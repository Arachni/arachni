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
        @instance_busyness  = {}
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

                chunk_cnt = 3

                chunks = paths_to_focus_on.chunk( chunk_cnt )
                @framework.opts.focus_scan_on = chunks.pop

                chunks.each {
                    |chunk|
                    begin
                        @instances << spawn( chunk )
                    rescue Exception => e
                        ap e
                        ap e.backtrace
                    end
                }

                @instances.each_with_index {
                    |instance, i|

                    instance_conn = connect_to_instance( instance )

                    jobs << Thread.new {
                        instance_conn.framework.run

                        break_loop = false
                        while( !break_loop )
                            begin
                                ap 'RUNNING SLAVE: ' + instance['url']
                                sleep( 10 )
                                @instance_busyness[instance['url']] = instance_conn.framework.busy?
                                break_loop = !@instance_busyness[instance['url']]
                            rescue Exception => e
                                ap e
                                ap e.backtrace
                            end
                        end
                        ap 'FINISHED SLAVE: ' + instance['url']
                    }
                }

            end

            jobs << Thread.new {
                @framework.run
                sleep( 10 )

                while( @framework.busy? )
                    ap 'RUNNING MASTER'
                    sleep( 10 )
                end

                ap 'FINISHED MASTER'
            }

            jobs.each { |job| job.join }


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

        begin
            @framework.clean_up!( skip_audit_queue )
            plugin_results = @framework.get_plugin_store

            @instances.each {
                |instance|
                instance_conn = connect_to_instance( instance )
                instance_conn.framework.clean_up!( skip_audit_queue )
                plugin_results.merge!( YAML::load( instance_conn.framework.get_plugin_store ) )
            }

            @framework.set_plugin_store( plugin_results )
        rescue Exception => e
            # ap e
            # ap e.backtrace
        end

        return true
    end

    def pause!
        @framework.pause!
        @instances.each {
            |instance|
            connect_to_instance( instance ).framework.pause!
        }
        return true
    end

    def resume!
        @framework.resume!
        @instances.each {
            |instance|
            connect_to_instance( instance ).framework.resume!
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
        tries = 0
        begin
            @master.framework.register_issue( results.to_yaml )
        rescue Errno::EPIPE, Timeout::Error, EOFError
            ap 'RETRYING: '+ tries.to_s
            tries += 1
            retry if tries < 5
        rescue Exception => e
            ap e
            ap e.backtrace
        end
    end

    def register_issue( results )
        @framework.modules.class.register_results( YAML::load( results ) )
        return true
    end

    def spawn( urls )

        opts = @framework.opts.to_h.deep_clone

        self_url = URI( opts['datastore'][:dispatcher_url] )
        self_url.port = @framework.opts.rpc_port
        self_url = self_url.to_s

        self_token = @opts.datastore[:token]

        dispatchers = nil
        3.times{
            begin
                dispatchers   = dispatcher.node.neighbours_with_info
                break
            rescue Exception => e
                ap e
                ap e.backtrace
                retry
            end
        }

        @used_pipe_ids ||= []
        @used_pipe_ids << dispatcher.node.info['pipe_id']

        pref_dispatcher_url = nil
        dispatchers.each {
            |node|
            if !@used_pipe_ids.include?( node['pipe_id'] )
                pref_dispatcher_url = node['url']
                @used_pipe_ids << node['pipe_id']
                break
            end
        }

        pref_dispatcher = connect_to_dispatcher( pref_dispatcher_url )

        instance_hash = pref_dispatcher.dispatch( self_url, {
            'rank'   => 'slave',
            'target' => @opts.url.to_s
        })

        instance = connect_to_instance( instance_hash )

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
            return { 'url' => instance_hash['url'], 'token' => instance_hash['token'] }
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
                buffer |= connect_to_instance( instance ).service.output.map {
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

    def progress_data
        data = {
            'messages'  => @framework.flush_buffer,
            'issues'    => YAML::load( issues ),
            'stats'     => {},
            'instances' => {}
        }

        stats = []
        begin
            stat_hash = {}
            @framework.stats( true, true ).each {
                |k, v|
                stat_hash[k.to_s] = v
            }

            if @framework.opts.datastore[:dispatcher_url]
                self_url = URI( @framework.opts.datastore[:dispatcher_url] )
                self_url.port = @framework.opts.rpc_port

                data['instances'][0] = stat_hash.dup
                data['instances'][0]['url'] = self_url.to_s.gsub( 'https://', '@' )
                data['instances'][0]['busy'] = @framework.busy? || false
            end

            stats << stat_hash
        rescue Exception => e
            ap e
            ap e.backtrace
        end

        ins_data = []
        begin
            @instances.each_with_index {
                |instance, i|
                tmp = connect_to_instance( instance ).framework.progress_data
                data['instances'][i+1] = tmp['stats']
                data['instances'][i+1]['url'] = instance['url'].gsub( 'https://', '@' )
                data['instances'][i+1]['busy'] = @instance_busyness[instance['url']] || false
                ins_data << tmp.deep_clone
            }

            ins_data.each {
                |prog_data|
                data['messages'] |= prog_data['messages']
                data['issues'] |= YAML::load( prog_data['issues'] )
                stats << prog_data['stats']
            }

            data['stats'] = merge_stats( stats )
        rescue Exception => e
            ap e
            ap e.backtrace
        end

        data['issues'] = YAML.dump( data['issues'] )

        return data
    end

    def dispatcher
        Arachni::RPC::XML::Client::Dispatcher.new( @opts, @opts.datastore[:dispatcher_url] )
    end

    def connect_to_instance( instance )
        @tokens ||= {}
        @tokens[instance['url']] = instance['token'] if instance['token']
        return Arachni::RPC::XML::Client::Instance.new( @opts, instance['url'], @tokens[instance['url']] )
    end

    def connect_to_dispatcher( url )
        Arachni::RPC::XML::Client::Dispatcher.new( @opts, url )
    end

    def merge_stats( stats )

        final_stats = stats.pop
        return {} if !final_stats || final_stats.empty?

        final_stats['current_pages'] = [ ]
        final_stats['current_pages'] << final_stats['current_page'] if final_stats['current_page']

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
            stats.each {
                |instats|

                ( avg | total ).each {
                    |k|
                    final_stats[k.to_s] += Float( instats[k.to_s] )
                }

                final_stats['current_pages'] << instats['current_page'] if instats['current_page']
            }

            avg.each {
                |k|
                final_stats[k.to_s] /= stats.size + 1
            }
        rescue Exception => e
            ap e
            ap e.backtrace
        end

        final_stats['sitemap_size'] = @sitemap.size if @sitemap

        return final_stats
    end

    def stats( fresh )

        stats = []
        begin
            stats << @framework.stats( fresh, true )
        rescue
            return {}
        end

        begin
            stats = @instances.map { |instance| connect_to_instance( instance ).framework.stats( fresh ) }
        rescue Exception => e
            ap e
            ap e.backtrace
        end

        final_stats = {}
        begin
            final_stats = merge_stats( stats )
        rescue Exception => e
            ap e
            ap e.backtrace
        end

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
            # ap e
            # ap e.backtrace
        end

        return false
    end

    def issues
        begin
            data = []

            @framework.audit_store( true ).issues.each {
                |issue|

                tmp_issue = issue.deep_clone

                if !issue.variations[0]['regexp_match']
                    tmp_issue.variations = []
                else
                    tmp_issue.variations = [tmp_issue.variations.pop]
                end

                data << tmp_issue
            }

            return YAML.dump( data )
        rescue Exception => e
            # ap e
            # ap e.backtrace
        end

        return YAML.dump( [] )
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
