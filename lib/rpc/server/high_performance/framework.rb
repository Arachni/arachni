=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'em-synchrony'

module Arachni

require Options.instance.dir['lib'] + 'rpc/server/framework'
require Options.instance.dir['lib'] + 'rpc/server/module/manager'
require Options.instance.dir['lib'] + 'rpc/server/plugin/manager'

module RPC
class Server
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

    MAX_CONCURRENCY = 20

    attr_reader :instances

    include Arachni::Module::Utilities

    def initialize( opts )
        # this is the local framework
        @framework = Arachni::RPC::Server::Framework.new( opts )

        @opts    = @framework.opts
        @modules = @framework.modules
        @plugins = @framework.plugins

        # holds all running instances
        @instances = []

        @sitemap = []
        @crawling_done = nil

        # if we're a slave this var will hold the URL of our master
        @master_url = ''
    end

    #
    # @see Arachni::RPC::Server::Framework#busy?
    #
    def busy?( include_slaves = true, &block )
        busyness = [ @framework.busy? ]

        if @instances.empty? || !include_slaves
            block.call( busyness[0] )
            return
        end

        ::EM::Iterator.new( @instances, @instances.size ).map( proc {
            |instance, iter|
            i_client = connect_to_instance( instance )
            i_client.framework.busy? {
                |res|
                i_client.close
                iter.return( res )
            }
        }, proc {
            |res|
            busyness << res
            busyness.flatten!
            block.call( !busyness.reject{ |is_busy| !is_busy }.empty? )
        })
    end

    #
    # @see Arachni::RPC::Server::Framework#debug?
    #
    def debug?
        @@debug
    end

    #
    # @see Arachni::RPC::Server::Framework#verbose?
    #
    def verbose?
        @@verbose
    end

    #
    # @see Arachni::RPC::Server::Framework#lsplug
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
    # Returns true if running in HPG (High Performance Grid) mode, false otherwise.
    #
    # @return   [Bool]
    #
    def high_performance?
        @framework.opts.grid_mode == 'high_performance'
    end

    #
    # Starts the audit.
    #
    def run

        EventMachine.add_periodic_timer(5) do
            print "EventMachine::Connection objects: "
            puts ObjectSpace.each_object( EventMachine::Connection ) {}

            print "Active connections: "
            puts ::EventMachine::connection_count
        end

        ::EM.defer {
            if high_performance?

                #
                # We're in HPG (High Perfrmance Grid) mode,
                # things are going to get weird...
                #

                # since the scan is distributed by way of assigning
                # a list of URLs to each instance we are required to
                # crawl first.
                @framework.opts.spider_first = true

                # start the crawl and store the URLs in the sitemap
                Arachni::Spider.new( @framework.opts ).run {
                    |page|
                    @sitemap << page.url
                }
                @crawling_done = true

                # get the Dispatchers with unique Pipe IDs
                # in order to take advantage of line aggregation
                prefered_dispatchers {
                    |pref_dispatchers|

                    # decide in how many chunks to split the sitemap
                    chunk_cnt = pref_dispatchers.size + 1

                    chunks = @sitemap.chunk( chunk_cnt )

                    # set the URLs to be audited by the local instance
                    @framework.opts.focus_scan_on = chunks.pop

                    chunks.each_with_index {
                        |chunk, i|
                        # spawn a remote instance and assign a chunk of URLs to it
                        spawn( chunk, pref_dispatchers[i] ) {
                            |inst|
                            @instances << inst
                        }
                    }
                }
            end

            @framework.run
        }

        return true
    end

    #
    # @see Arachni::RPC::Server::Framework#lsmod
    #
    def lsmod( &block )
        block.call( @framework.lsmod )
    end

    #
    # @see Arachni::RPC::Server::Framework#lsplug
    #
    def lsplug( &block )
        block.call( @framework.lsplug )
    end

    #
    # If the scan needs to be aborted abruptly this method takes care of
    # any unfinished business (like running plug-ins).
    #
    def clean_up!( &block )
        @framework.clean_up!( true )
        plugin_results = @framework.get_plugin_store

        if @instances.empty?
            block.call if block_given?
            return
        end

        ::EM::Iterator.new( @instances, @instances.size ).map( proc {
            |instance, iter|
            instance_conn = connect_to_instance( instance )

            instance_conn.framework.clean_up! {
                instance_conn.framework.get_plugin_store {
                    |plugin_store|
                    instance_conn.close
                    iter.return( plugin_store )
                }
            }

        }, proc {
            |res|
            while( result = res.pop )
                plugin_results.merge!( result )
            end
            block.call
        })
    end

    #
    # @see Arachni::RPC::Server::Framework#pause!
    #
    def pause!
        @framework.pause!
        ::EM::Iterator.new( @instances, @instances.size ).each {
            |instance, iter|
            i_client = connect_to_instance( instance )
            i_client.framework.pause!{ i_client.close; iter.next }
        }
        return true
    end

    #
    # @see Arachni::RPC::Server::Framework#resume!
    #
    def resume!
        @framework.resume!
        ::EM::Iterator.new( @instances, @instances.size ).each {
            |instance, iter|
            i_client = connect_to_instance( instance )
            i_client.framework.resume!{ i_client.close; iter.next }
        }
        return true
    end

    def get_plugin_store
        @framework.get_plugin_store
    end

    #
    # Set the URL and authentication token required to connect to our master.
    #
    # @param    [String]    url     master's URL in 'https://hostname:port' form
    # @param    [String]    token   master's autentication token
    #
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

    #
    # Returns the master's URL
    #
    # @return   [String]
    #
    def master
        @master_url
    end

    #
    # Registers a YAML serialized array holding [Arachni::Issue] objects with the local instance.
    #
    # Primarily used by slaves to register any issue they find on the spot.
    #
    # @param    [String]    results     YAML dump of an array with YAML serialized [Arachni::Issue] objects
    #
    def register_issue( results )
        @framework.modules.class.register_results( YAML::load( results ) )
        return true
    end

    #
    # Returns the merged output of all running instances.
    #
    # This is going probably to be wildly out of sync and lack A LOT of messages.
    #
    # It's here to give the notion of scan progress to the end-user rather than
    # provide an accurate depiction of the actual progress.
    #
    # @return   [Array]
    #
    def output( &block )

        buffer = @framework.flush_buffer

        if @instances.empty?
            block.call( buffer )
            return
        end

        ::EM::Iterator.new( @instances, MAX_CONCURRENCY ).map( proc {
            |instance, iter|
            i_client = connect_to_instance( instance )
            i_client.service.output {
                |out|
                i_client.close
                iter.return( out )
            }
        }, proc {
            |out|
            block.call( (buffer | out).flatten )
        })
    end

    #
    # Returns the status of the instance as a string.
    #
    # Possible values are:
    #  o crawling
    #  o paused
    #  o done
    #  o busy
    #
    # @return   [String]
    #
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

    #
    # Returns aggregated progress data and helps to limit the amount of calls
    # required in order to get an accurate depiction of a scan's progress and includes:
    #  o output messages
    #  o discovered issues
    #  o overall statistics
    #  o overall scan status
    #  o statistics of all instances individually
    #
    # @return   [Hash]
    #
    def progress_data( opts= {}, &block )

        if opts[:messages].nil?
            include_messages = true
        else
            include_messages = opts[:messages]
        end

        if opts[:slaves].nil?
            include_slaves = true
        else
            include_slaves = opts[:slaves]
        end

        if opts[:issues].nil?
            include_issues = true
        else
            include_issues = opts[:issues]
        end

        data = {
            'stats'     => {},
            'status'    => status,
            'busy'      => @framework.busy?
        }

        data['messages']  = @framework.flush_buffer if include_messages
        data['issues']    = YAML::load( issues ) if include_issues
        data['instances'] = {} if include_slaves

        stats = []
        stat_hash = {}
        @framework.stats( true, true ).each {
            |k, v|
            stat_hash[k.to_s] = v
        }

        if @framework.opts.datastore[:dispatcher_url] && include_slaves
            data['instances'][self_url] = stat_hash.dup
            data['instances'][self_url]['url'] = self_url
            data['instances'][self_url]['status'] = status
        end

        stats << stat_hash

        if @instances.empty? || !include_slaves
            data['stats'] = merge_stats( stats )
            data['instances'] = data['instances'].values if include_slaves
            block.call( data )
            return
        end

        ::EM::Iterator.new( @instances, MAX_CONCURRENCY ).map( proc {
            |instance, iter|
            i_client = connect_to_instance( instance )
            i_client.framework.progress_data( opts ) {
                |tmp|

                i_client.close
                tmp['url'] = instance['url']
                iter.return( tmp )
            }
        }, proc {
            |slave_data|

            stats = []
            slave_data.each {
                |slave|
                data['messages']  |= slave['messages'] if include_messages
                data['issues']    |= slave['issues'] if include_issues

                if include_slaves
                    url = slave['url']
                    data['instances'][url]           = slave['stats']
                    data['instances'][url]['url']    = url
                    data['instances'][url]['status'] = slave['status']
                end

                stats << slave['stats']
            }

            if include_slaves
                sorted_data_instances = {}
                data['instances'].keys.sort.each {
                    |url|
                    sorted_data_instances[url] = data['instances'][url]
                }
                data['instances'] = sorted_data_instances.values
            end

            data['stats'] = merge_stats( stats )
            block.call( data )
        })
    end

    #
    # Scan statistics
    #
    # @return   [Hash]
    #
    def stats( fresh = true )

        stats = []
        begin
            stats << @framework.stats( fresh, true )
        rescue
            return {}
        end

        begin
            stats = @instances.map { |instance| connect_to_instance( instance ).framework.stats( fresh ) }
        rescue Exception => e
            # ap e
            # ap e.backtrace
        end

        final_stats = {}
        begin
            final_stats = merge_stats( stats )
        rescue Exception => e
            # ap e
            # ap e.backtrace
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
            store =  @framework.audit_store( true )
            store.framework = nil
            return YAML.dump( store )
        rescue Exception => e
            # ap e
            # ap e.backtrace
        end

        return false
    end

    #
    # Returns a YAML dump of all discovered [Arachni::Issue]s.
    #
    # @return   [String]
    #
    def issues
        begin
            data = []

            @framework.audit_store( true ).issues.each {
                |issue|

                tmp_issue = issue.deep_clone
                tmp_issue.variations = []

                data << tmp_issue
            }

            return YAML.dump( data )
        rescue Exception => e
            # ap e
            # ap e.backtrace
        end

        return YAML.dump( [] )
    end

    #
    # Connects to a remote Instance.
    #
    # @param    [Hash]  instance    the hash must hold the 'url' and the 'token'.
    #                                   In subsequent calls the 'token' can be omitted.
    #
    def connect_to_instance( instance )
        @tokens  ||= {}
        # @i_conns ||= {}

        @tokens[instance['url']] = instance['token'] if instance['token']
        # return @i_conns[instance['url']] ||=
        return Arachni::RPC::Client::Instance.new( @opts, instance['url'], @tokens[instance['url']] )
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
    # some BrBRPC libraries of other languages map remote objects to local objects
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
        @master.framework.register_issue( results.to_yaml ){}
    end

    def prefered_dispatchers( &block )
        @used_pipe_ids ||= []

        dispatcher.node.info {
            |info|

            @used_pipe_ids << info['pipe_id']
            dispatcher.node.neighbours_with_info {
                |dispatchers|

                ::EM::Iterator.new( dispatchers, MAX_CONCURRENCY ).map( proc {
                    |dispatcher, iter|
                    d_client = connect_to_dispatcher( dispatcher['url'] )
                    d_client.alive? {
                        |res|

                        d_client.close
                        if !res.rpc_exception?
                            iter.return( dispatcher )
                        else
                            iter.return( nil )
                        end
                    }
                }, proc {
                    |nodes|

                    pref_dispatcher_urls = []
                    nodes.each {
                        |node|
                        if !@used_pipe_ids.include?( node['pipe_id'] )
                            @used_pipe_ids << node['pipe_id']
                            pref_dispatcher_urls << node['url']
                        end
                    }

                    block.call( pref_dispatcher_urls )
                })
            }
        }
    end

    def spawn( urls, prefered_dispatcher, &block )

        opts = @framework.opts.to_h.deep_clone

        self_token = @opts.datastore[:token]

        pref_dispatcher = connect_to_dispatcher( prefered_dispatcher )

        pref_dispatcher.dispatch( self_url, {
            'rank'   => 'slave',
            'target' => @opts.url.to_s,
            'master' => self_url
        }) {
            |instance_hash|

            pref_dispatcher.close
            instance = connect_to_instance( instance_hash )

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

            instance.opts.set( opts ){
                instance.framework.set_master( self_url, self_token ){
                    instance.modules.load( opts['mods'] ) {
                        instance.plugins.load( opts['plugins'] ) {
                            instance.framework.run {

                                instance.close
                                block.call( {
                                    'url' => instance_hash['url'],
                                    'token' => instance_hash['token'] }
                                )
                            }
                        }
                    }
                }
            }
        }
    end

    def self_url
        @self_url ||= nil
        return @self_url if @self_url

        port = @framework.opts.rpc_port
        d_port = @framework.opts.datastore[:dispatcher_url].split( ':', 2 )[1]
        @self_url = @framework.opts.datastore[:dispatcher_url].gsub( d_port, port.to_s )
    end

    def dispatcher
       connect_to_dispatcher( @opts.datastore[:dispatcher_url] )
    end

    def connect_to_dispatcher( url )
        # @d_conns ||= {}
        # @d_conns[url] ||=
        Arachni::RPC::Client::Dispatcher.new( @opts, url )
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
            # ap e
            # ap e.backtrace
        end

        final_stats['sitemap_size'] = @sitemap.size if @sitemap

        return final_stats
    end



end

end
end
end
end
