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
# Wraps the framework of the local instance and the frameworks of all
# remote slaves (when in High Performance Grid mode) into a neat, little,
# easy to handle package.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Framework

    attr_reader :instances

    def initialize( opts )
        # this is the local framework
        @framework = Arachni::RPC::XML::Server::Framework.new( opts )

        @opts = @framework.opts
        @modules = @framework.modules
        @plugins = @framework.plugins

        @instances = []
        @instance_busyness  = {}
        @sitemap = []
        @crawling_done = nil
        @master_url = ''
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

    def high_performance?
        @framework.opts.grid_mode == 'high_performance'
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
            if high_performance?

                @framework.opts.spider_first = true

                Arachni::Spider.new( @framework.opts ).run {
                    |page|
                    @sitemap << page.url
                }
                @crawling_done = true

                pref_dispatchers = prefered_dispatchers()
                chunk_cnt = pref_dispatchers.size + 1

                chunks = @sitemap.chunk( chunk_cnt )
                @framework.opts.focus_scan_on = chunks.pop

                chunks.each_with_index {
                    |chunk, i|
                    begin
                        @instances << spawn( chunk, pref_dispatchers[i] )
                    rescue Exception => e
                        ap e
                        ap e.backtrace
                    end
                }

                @instances.each_with_index {
                    |instance, i|

                    jobs << Thread.new {
                        instance_conn = connect_to_instance( instance )
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

            jobs = []
            results_queue = Queue.new
            @instances.each {
                |instance|
                jobs << Thread.new {
                    instance_conn = connect_to_instance( instance )
                    instance_conn.framework.clean_up!( skip_audit_queue )
                    results_queue << instance_conn.framework.get_plugin_store
                }
            }

            jobs.each { |job| job.join }

            while( !results_queue.empty? && result = results_queue.pop )
                plugin_results.merge!( YAML::load( result ) )
            end


            @framework.set_plugin_store( plugin_results )
        rescue Exception => e
            # ap e
            # ap e.backtrace
        end

        return true
    end

    def pause!
        @framework.pause!

        jobs = []
        @instances.each {
            |instance|
            jobs << Thread.new {
                connect_to_instance( instance ).framework.pause!
            }
        }
        jobs.each { |job| job.join }
        return true
    end

    def resume!
        @framework.resume!

        jobs = []
        @instances.each {
            |instance|
            jobs << Thread.new {
                connect_to_instance( instance ).framework.resume!
            }
        }
        jobs.each { |job| job.join }
        return true
    end

    def get_plugin_store
        @framework.get_plugin_store.to_yaml
    end

    def set_master( url, token )
        @master_url = url
        @master = connect_to_instance( { 'url' => url, 'token' => token } )

        @framework.modules.class.do_not_store!
        @framework.modules.class.on_register_results {
            |results|
            report_issue_to_master( results )
        }

        return true
    end

    def master
        @master_url
    end

    def register_issue( results )
        @framework.modules.class.register_results( YAML::load( results ) )
        return true
    end

    def output

        buffer = @framework.flush_buffer
        begin
            jobs = []
            output_q = Queue.new
            @instances.each_with_index {
                |instance, i|
                jobs << Thread.new {
                    buffer |= connect_to_instance( instance ).service.output
                }
            }

            jobs.each { |job| job.join }
        rescue Exception => e
            ap e
            ap e.backtrace
        end

        return buffer.flatten
    end

    def status
        if !@crawling_done && master.empty? && high_performance?
            return 'crawling'
        elsif @framework.paused?
            return 'paused'
        elsif !@framework.busy?
            return 'done'
        else
            return 'busy'
        end
    end

    def progress_data
        data = {
            'messages'  => @framework.flush_buffer,
            'issues'    => YAML::load( issues ),
            'stats'     => {},
            'status'    => status,
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
                self_url = self_url.to_s.gsub( 'https://', '@' )

                data['instances'][self_url] = stat_hash.dup
                data['instances'][self_url]['url'] = self_url
                data['instances'][self_url]['status'] = status
            end

            stats << stat_hash
        rescue Exception => e
            ap e
            ap e.backtrace
        end

        ins_data = []
        begin
            jobs = []
            @instances.each_with_index {
                |instance, i|
                jobs << Thread.new {
                    begin
                        tmp = connect_to_instance( instance ).framework.progress_data
                        url = instance['url'].gsub( 'https://', '@' )

                        data['instances'][url] = tmp['stats']
                        data['instances'][url]['url'] = url
                        data['instances'][url]['status'] = tmp['status']

                        ins_data << tmp.deep_clone
                    rescue
                    end
                }
            }

            jobs.each { |job| job.join }

            sorted_data_instances = {}
            data['instances'].keys.sort.each {
                |url|
                sorted_data_instances[url] = data['instances'][url]
            }
            data['instances'] = sorted_data_instances.values

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

    #
    # some XMLRPC libraries of other languages map remote objects to local objects
    # creating an invalid syntax situation since the aforementioned languages
    # may not allow "?" or "!" in method names.
    #
    # so we alias these methods to make it easier on 3rd party developers.
    #
    alias :pause :pause!
    alias :is_paused :paused?
    alias :resume :resume!
    alias :clean_up :clean_up!
    alias :is_busy :busy?
    alias :is_debug :debug?
    alias :is_verbose :verbose?


    private

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

    def prefered_dispatchers
        @used_pipe_ids ||= []
        @used_pipe_ids << dispatcher.node.info['pipe_id']

        dispatchers = nil
        3.times {
            begin
                dispatchers = dispatcher.node.neighbours_with_info
                break
            rescue Exception => e
                ap e
                ap e.backtrace
            end
        }

        node_q = Queue.new
        jobs = []
        dispatchers.each {
            |node|
            jobs << Thread.new {
                begin
                    node_q << node if connect_to_dispatcher( node['url'] ).alive?
                rescue Exception => e
                    ap e
                    ap e.backtrace
                end
            }
        }

        jobs.each { |job| job.join }

        pref_dispatcher_urls = []
        while( !node_q.empty? && node = node_q.pop )
            if !@used_pipe_ids.include?( node['pipe_id'] )
                @used_pipe_ids << node['pipe_id']
                pref_dispatcher_urls << node['url']
            end
        end

        return pref_dispatcher_urls
    end

    def spawn( urls, prefered_dispatcher )

        opts = @framework.opts.to_h.deep_clone

        self_url = URI( opts['datastore'][:dispatcher_url] )
        self_url.port = @framework.opts.rpc_port
        self_url = self_url.to_s

        self_token = @opts.datastore[:token]

        pref_dispatcher = connect_to_dispatcher( prefered_dispatcher )

        instance_hash = pref_dispatcher.dispatch( self_url, {
            'rank'   => 'slave',
            'target' => @opts.url.to_s,
            'master' => self_url
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

        return final_stats if stats.empty?

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



end

end
end
end
end
end
