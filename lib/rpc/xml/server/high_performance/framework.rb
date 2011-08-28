=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

require Options.instance.dir['lib'] + 'rpc/xml/server/framework'
require Options.instance.dir['lib'] + 'rpc/xml/server/module/manager'
require Options.instance.dir['lib'] + 'rpc/xml/server/plugin/manager'

module RPC
module XML
module Server
module HighPerformance

#
# Extends the Framework adding XML-RPC specific functionality
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Framework

    attr_reader :instances

    # #
    # # Our run() method needs to run the parent's run() method in
    # # a separate thread.
    # #
    # alias :old_run :run
#
    # # make this inherited methods visible again
    # private :old_run, :stats, :pause!, :paused?, :resume!, :lsmod, :modules, :lsplug, :clean_up!
    # public  :stats, :pause!, :paused?, :resume!, :lsmod, :modules, :lsplug, :clean_up!

    #
    # some XMLRPC libraries of other languages map remote objects to local objects
    # creating an invalid syntax situation since the aforementioned languages
    # may not allow "?" or "!" in method names.
    #
    # so we alias these methods to make it easier on 3rd party developers.
    #
    # alias :pause :pause!
    # alias :is_paused :paused?
    # alias :resume :resume!
    # alias :clean_up :clean_up!
    # alias :is_busy :busy?
    # alias :is_debug :debug?
    # alias :is_verbose :verbose?

    def initialize( opts )
        # this is the local framework
        @framework = Arachni::RPC::XML::Server::Framework.new( opts )

        @opts = @framework.opts
        @modules = @framework.modules
        @plugins = @framework.plugins

        @instances = []
    end

    #
    # Aborts the running audit.
    #
    def abort!
        @job.kill
        return true
    end

    #
    # Checks to see if an audit is running.
    #
    # @return   [Bool]
    #
    def busy?
        return false if !@job
        return @job.alive?
    end

    #
    # Checks whether the framework is in debug mode
    #
    def debug?
        @@debug
    end

    #
    # Checks whether the framework is in debug mode
    #
    def verbose?
        @@verbose
    end

    #
    # Returns an array of hashes with information
    # about all available reports
    #
    # @return    [Array<Hash>]
    #
    def lsplug

        plug_info = []

        @plugins.available( ).each {
            |plugin|

            info = @plugins[plugin].info

            info[:plug_name]   = plugin
            info[:path]        = @plugins.name_to_path( plugin )

            info[:options] = [info[:options]].flatten.compact.map {
                |opt|
                opt_h = opt.to_h
                opt_h['default'] = '' if opt_h['default'].nil?
                opt_h['type']    = opt.type
                opt_h
            }

            plug_info << info
        }

        @plugins.clear( )

        return plug_info
    end


    #
    # Starts the audit.
    #
    # The audit is started in a new thread to avoid service blocking.
    #
    def run
        Thread.abort_on_exception = true

        @job = Thread.new {

            jobs = []
            if @framework.opts.grid_mode == 'high_performance'

                @framework.opts.spider_first = true

                paths_to_focus_on = []
                Arachni::Spider.new( @framework.opts ).run {
                    |page|
                    paths_to_focus_on << page.url
                }

                @sitemap = paths_to_focus_on
                chunks = paths_to_focus_on.chunk( 2 )
                @framework.opts.focus_scan_on = chunks[0]

                @instances << spawn( chunks[1] )
                @instances.each {
                    |instance|
                    jobs << Thread.new {
                        instance.framework.run

                        break_loop = false
                        while( !break_loop )
                            begin
                                ap 'RUNNING'
                                sleep( 3 )
                                break_loop = !instance.framework.busy?
                            rescue Exception => e
                                ap e
                                ap e.backtrace
                            end
                        end
                    }
                }

            end

            @framework.run
            jobs.each { |job| job.join }

            while( @framework.busy? )
                sleep( 3 )
                # ap output
            end
        }

        return true
    end

    def lsmod
        @framework.lsmod
    end

    def lsplug
        @framework.lsplug
    end

    def clean_up!( skip_audit_queue = false )

        @framework.clean_up!( skip_audit_queue )
        plugin_results = @framework.get_plugin_store

        @instances.each {
            |instance|
            instance.framework.clean_up!( skip_audit_queue )
            plugin_results.merge!( YAML::load( instance.framework.get_plugin_store ) )
        }

        @framework.set_plugin_store( plugin_results )
        return true
    end

    def pause!( skip_audit_queue = false )
        @framework.pause!
        @instances.each {
            |instance|
            instance.framework.pause!
        }
        return true
    end

    def resume!( skip_audit_queue = false )
        @framework.resume!
        @instances.each {
            |instance|
            instance.framework.resume!
        }
        return true
    end

    def get_plugin_store
        @framework.get_plugin_store.to_yaml
    end


    def set_master( url, token )
        @master = connect_to_instance( { 'url' => url, 'token' => token } )

        @framework.modules.class.do_not_store!
        @framework.modules.class.on_register_results {
            |results|
            report_issue_to_master( results )
        }

        return true
    end

    def report_issue_to_master( results )
        3.times {
            begin
                @master.framework.register_issue( results.to_yaml )
                return
            rescue Exception => e
                ap e
                ap e.backtrace
            end
        }
    end

    def register_issue( results )
        @framework.modules.class.register_results( YAML::load( results ) )
        return true
    end

    def spawn( urls )

        opts = @framework.opts.to_h.dup

        self_url = URI( opts['datastore'][:dispatcher_url] )
        self_url.port = @framework.opts.rpc_port
        self_url = self_url.to_s

        self_token = @opts.datastore[:token]

        instance = connect_to_instance( dispatcher.dispatch( self_url ) )

        begin
            opts['url'] = opts['url'].to_s
            opts['focus_scan_on'] = urls

            opts['grid_mode'] = ''

            opts.delete( 'dir' )
            opts.delete( 'rpc_port' )
            opts.delete( 'rpc_address' )
            opts['datastore'].delete( :dispatcher_url )
            opts['datastore'].delete( :token )

            opts['exclude'].each_with_index {
                |v, i|
                opts['exclude'][i] = v.source
            }

            opts['include'].each_with_index {
                |v, i|
                opts['include'][i] = v.source
            }

            instance.opts.set( opts )
            instance.framework.set_master( self_url, self_token )
            instance.modules.load( opts['mods'] )
            instance.plugins.load( opts['plugins'] )
            return instance
        rescue Exception => e
            ap e
            ap e.backtrace
        end
    end

    def output

        buffer = @framework.flush_buffer
        begin
            @instances.each_with_index {
                |instance, i|
                buffer |= instance.service.output.map {
                    |msg|
                    { msg.keys[0] => "Spawn #{i}: " + msg.values[0] }

                }
            }
        rescue Exception => e
            ap e
            ap e.backtrace
        end

        return buffer.flatten
    end

    def dispatcher
        @dispatcher ||=
            Arachni::RPC::XML::Client::Dispatcher.new( @opts, @opts.datastore[:dispatcher_url] )
    end

    def connect_to_instance( instance )
        @instance_cache ||= {}
        @instance_cache[instance['url']] ||=
            Arachni::RPC::XML::Client::Instance.new( @opts, instance['url'], instance['token'] )
    end

    def stats( fresh )
        final_stats = @framework.stats( fresh, true )

        total = [
            :requests,
            :responses,
            :time_out_count,
            :avg,
            :sitemap_size,
            :auditmap_size,
            :max_concurrency
        ]

        avg = [
            :progress,
            :curr_res_time,
            :curr_res_cnt,
            :curr_avg,
            :average_res_time
        ]

        begin
            @instances.each {
                |instance|

                instats = instance.framework.stats( fresh )

                ( avg | total ).each {
                    |k|
                    final_stats[k] += Float( instats[k.to_s] )
                }
            }

            avg.each {
                |k|
                final_stats[k] /= @instances.size + 1
            }

        rescue Exception => e
            ap e
            # ap e.faultCode
            # ap e.faultString
            ap e.backtrace
        end

        final_stats[:sitemap_size] = @sitemap.size if @sitemap

        return final_stats
    end

    #
    # Returns the results of the audit.
    #
    # @return   [YAML]  YAML dump of the results hash
    #
    def report
        exception_jail {
            return false if !@job
            store =  @framework.audit_store( true )
            store.framework = ''
            return YAML.dump( store.to_h.dup )
        }
        return false
    end

    #
    # Returns the results of the audit as a serialized AuditStore object.
    #
    # @return   [YAML]  YAML dump of the AuditStore
    #
    def auditstore
        begin
            return false if !@job
            store =  @framework.audit_store( true )
            store.framework = nil
            return YAML.dump( store )
        rescue Exception => e
            ap e
            ap e.backtrace
        end

        return false
    end

    def version
        @framework.version
    end

    def revision
        @framework.version
    end

    def modules
        @modules
    end

    def opts
        @framework.opts
    end

    def paused?
        @framework.paused?
    end

    def plugins
        @plugins
    end

    #
    # Enables debugging output
    #
    def debug_on
        @@debug = true
    end

    #
    # Disables debugging output
    #
    def debug_off
        @@debug = false
    end

    #
    # Enables debugging output
    #
    def verbose_on
        @@verbose = true
    end

    #
    # Disables debugging output
    #
    def verbose_off
        @@verbose = false
    end

end

end
end
end
end
end
