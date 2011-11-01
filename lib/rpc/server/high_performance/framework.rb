=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'ap'
require 'pp'
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

        @job = nil

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

        busyness = [ local_busy? ]

        if @instances.empty? || !include_slaves
            block.call( busyness[0] )
            return
        end

        ::EM::Iterator.new( @instances, @instances.size ).map( proc {
            |instance, iter|
            connect_to_instance( instance ).framework.busy? {
                |res|
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
        # EventMachine.add_periodic_timer( 1 ) do
            # print "Arachni::RPC::Client::Handler objects: "
            # puts ObjectSpace.each_object( Arachni::RPC::Client::Handler ) {}
#
            # print "Arachni::RPC::Server::Proxy objects: "
            # puts ObjectSpace.each_object( Arachni::RPC::Server::Proxy ) {}
#
            # puts "Active connections: #{::EM.connection_count}"
            # puts '--------------------------------------------'
        # end

        ::EM.defer {

            #
            # if we're in HPG mode do fancy stuff like distributing and balancing workload
            # as well as starting slave instances and deal with some lower level
            # operations of the local instance like running plug-ins etc...
            #
            # otherwise just run the local instance, nothing special...
            #
            if high_performance?
                @starting = true

                #
                # We're in HPG (High Performance Grid) mode,
                # things are going to get weird...
                #

                # we'll need analyze the pages prior to assigning
                # them to each instance at the element level so as to gain
                # more granular control over the assigned workload
                #
                # put simply, we'll need to perform some magic in order
                # to prevent different instances from auditing the same elements
                # and wasting bandwidth
                #
                # for example: search forms, logout links and the like will
                # most likely exist on most pages of the site and since each
                # instance is assigned a set of URLs/pages to audit they will end up
                # with common elements so we have to prevent instances from
                # performing identical checks.
                #
                # interesting note: should previously unseen elements dynamically
                # appear during the audit they will override these restrictions
                # and each instance will audit them at will.
                #
                pages = ::Arachni::Database::Hash.new

                # prepare the local instance (runs plugins and start the timer)
                @framework.prepare

                # we need to take our cues from the local framework as some
                # plug-ins may need the system to wait for them to finish
                # before moving on.
                sleep( 0.2 ) while @framework.paused?

                # start the crawl and extract all paths
                Arachni::Spider.new( @framework.opts ).run {
                    |page|
                    @sitemap << page.url
                    pages[page.url] = page
                }
                @crawling_done = true

                # the plug-ins may have update the framework page_queue
                # so we need to distribute these pages as well
                page_a = []
                page_q = @framework.get_page_queue
                while !page_q.empty? && page = page_q.pop
                    page_a << page
                    pages[page.url] = page
                end

                # get the Dispatchers with unique Pipe IDs
                # in order to take advantage of line aggregation
                prefered_dispatchers {
                    |pref_dispatchers|

                    # decide in how many chunks to split the paths
                    chunk_cnt = pref_dispatchers.size + 1

                    # split the URLs of the pages in equal chunks and group them
                    chunks = pages.keys.chunk( chunk_cnt )

                    # split the page array into chunks that will be distributed
                    # across the instances
                    page_chunks = page_a.chunk( chunk_cnt )

                    # assign us our fair share of plug-in discovered pages
                    @framework.update_page_queue( page_chunks.pop )

                    # remove duplicate elements across the (per instance) chunks
                    # while spreading them out evenly
                    elements = distribute_elements( chunks, pages )

                    # restrict the local instance to its assigned elements
                    restrict_to_elements!( elements.pop )

                    # set the URLs to be audited by the local instance
                    @framework.opts.restrict_paths = chunks.pop

                    chunks.each_with_index {
                        |chunk, i|

                        # spawn a remote instance, assign a chunk of URLs
                        # and elements to it and run it
                        spawn( chunk, page_chunks[i], elements[i], pref_dispatchers[i] ) {
                            |inst|
                            @instances << inst
                        }
                    }

                    # start the local instance
                    @job = Thread.new {
                        exception_jail{ @framework.audit }
                        @framework.override_sitemap!( @sitemap )
                        exception_jail{ @framework.clean_up! }
                    }
                    @starting = false

                    # empty out the Hash and remove temporary files
                    pages.clear
                }
            else
                # start the local instance
                @framework.run
            end

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
        @framework.override_sitemap!( @sitemap ) if high_performance?
        @framework.clean_up!( true )

        if @instances.empty?
            block.call if block_given?
            return
        end

        ::EM::Iterator.new( @instances, @instances.size ).map( proc {
            |instance, iter|
            instance_conn = connect_to_instance( instance )

            instance_conn.framework.clean_up! {
                instance_conn.framework.get_plugin_store {
                    |res|
                    iter.return( res )
                }
            }

        }, proc {
            |results|
            results << @framework.get_plugin_store
            update_plugin_results!( results )
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
            connect_to_instance( instance ).framework.pause!{ iter.next }
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
            connect_to_instance( instance ).framework.resume!{ iter.next }
        }
        return true
    end

    def get_plugin_store
        @framework.get_plugin_store
    end

    def restrict_to_elements!( elements )
        ::Arachni::Element::Auditable.restrict_to_elements!( elements )
        true
    end

    #
    # Set the URL and authentication token required to connect to our master.
    #
    # @param    [String]    url     master's URL in 'https://hostname:port' form
    # @param    [String]    token   master's authentication token
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

    def update_page_queue( pages )
        @framework.update_page_queue( pages )
        true
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
        @framework.modules.class.register_results( results )
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
            connect_to_instance( instance ).service.output {
                |out|
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
        elsif !local_busy?
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
            connect_to_instance( instance ).framework.progress_data( opts ) {
                |tmp|
                tmp['url'] = instance['url']
                iter.return( tmp )
            }
        }, proc {
            |slave_data|

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
        store =  @framework.audit_store( true )
        store.framework = nil
        return store
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
            Arachni::RPC::Client::Instance.new( @opts, instance['url'], @tokens[instance['url']] )
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

    def local_busy?
        return true if @starting

        if @job
            return @job.alive?
        else
            return @framework.busy?
        end
    end

    def report_issue_to_master( results )
        @master.framework.register_issue( results ){}
    end

    #
    # Takes the plug-in results of all the instances and merges them together.
    #
    def update_plugin_results!( results )
        info = {}
        formatted = {}

        results.each {
            |plugins|

            plugins.each {
                |name, res|
                next if !res

                formatted[name] ||= []
                formatted[name] << res[:results]

                info[name] = res.reject{ |k, v| k == :results } if !info[name]
            }
        }

        merged = {}
        formatted.each {
            |plugin, results|

            if !@plugins[plugin].distributable?
                res = results[0]
            else
                res = @plugins[plugin].merge( results )
            end
            merged[plugin] = info[plugin].merge( :results => res )
        }

        @framework.set_plugin_store( merged )
    end

    #
    # Returns an array containing unique and evenly distributed elements per chunk
    # for each instance.
    #
    def distribute_elements( chunks, pages )

        #
        # chunks = URLs to be assigned to each instance
        # pages = hash with URLs for key and Pages for values.
        #

        # groups together all the elements of all chunks
        elements_per_chunk = []
        chunks.each_with_index {
            |chunk, i|

            elements_per_chunk[i] ||= []
            chunk.each {
                |url|
                elements_per_chunk[i] |= build_elem_list( pages[url] )
            }
        }

        # removes elements from each chunk
        # that are also included in other chunks too
        #
        # this will leave us with the same grouping as before
        # but without duplicate elements across the chunks,
        # albeit with an non-optimal distribution amongst instances.
        #
        unique_chunks = elements_per_chunk.map.with_index {
            |chunk, i|
            chunk.reject {
                |item|
                elements_per_chunk[i..-1].flatten.count( item ) > 1
            }
        }

        # get them into proper order to be ready for proping up
        elements_per_chunk.reverse!
        unique_chunks.reverse!

        # evenly distributed elements across chunks
        # using the previously duplicate elements
        #
        # in order for elements to be moved between chunks they need to
        # have been available in the destination to begin with since
        # we can't assign an element to an instance which won't
        # have a page containing that element
        unique_chunks.each_with_index {
            |chunk, i|

            chunk.each {
                |item|
                next_c = unique_chunks[i+1]
                if next_c && (chunk.size > next_c.size ) &&
                    elements_per_chunk[i+1].include?( item )
                    unique_chunks[i].delete( item )
                    next_c << item
                end
            }
        }

        # set them in the same order as the original 'chunks' group
        return unique_chunks.reverse
    end

    def build_elem_list( page )
        list = []

        opts = {
            :no_auditor => true,
            :no_timeout => true,
            :no_injection_str => true
        }

        if @framework.opts.audit_links
            list |= page.links.map { |elem| elem.audit_id( nil, opts ) }.uniq
        end

        if @framework.opts.audit_forms
            list |= page.forms.map { |elem| elem.audit_id( nil, opts ) }.uniq
        end

        if @framework.opts.audit_cookies
            list |= page.cookies.map { |elem| elem.audit_id( nil, opts ) }.uniq
        end

        return list
    end

    #
    # Returns the dispatchers that have different Pipe IDs i.e. can be setup
    # in HPG mode; pretty simple at this point.
    #
    # TODO: implement filtering criteria and restrictions
    #
    def prefered_dispatchers( &block )

        # keep track of the Pipe IDs we've used
        @used_pipe_ids ||= []

        # get the info of the local dispatcher since this will be our
        # frame of reference
        dispatcher.node.info {
            |info|

            # add the Pipe ID of the local Dispatcher in order to avoid it later on
            @used_pipe_ids << info['pipe_id']

            # grab the rest of the Dispatchers of the Grid
            dispatcher.node.neighbours_with_info {
                |dispatchers|

                # make sure that each Dispatcher is alive before moving on
                ::EM::Iterator.new( dispatchers, MAX_CONCURRENCY ).map( proc {
                    |dispatcher, iter|
                    connect_to_dispatcher( dispatcher['url'] ).alive? {
                        |res|
                        if !res.rpc_exception?
                            iter.return( dispatcher )
                        else
                            iter.return( nil )
                        end
                    }
                }, proc {
                    |nodes|

                    # get the Dispatchers with unique Pipe IDs and send them
                    # to the block

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

    #
    # Spawns and runs a new remote instance
    #
    def spawn( urls, pages, elements, prefered_dispatcher, &block )

        opts = @framework.opts.to_h.deep_clone

        self_token = @opts.datastore[:token]

        pref_dispatcher = connect_to_dispatcher( prefered_dispatcher )

        pref_dispatcher.dispatch( self_url, {
            'rank'   => 'slave',
            'target' => @opts.url.to_s,
            'master' => self_url
        }) {
            |instance_hash|

            instance = connect_to_instance( instance_hash )

            opts['url'] = opts['url'].to_s
            opts['restrict_paths'] = urls

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

            # don't let the slaves run plug-ins that are not meant
            # to be distributed
            opts['plugins'].reject! {
                |k, v|
                !@plugins[k].distributable?
            }

            instance.opts.set( opts ){
                instance.framework.update_page_queue( pages ) {
                    instance.framework.restrict_to_elements!( elements ){
                        instance.framework.set_master( self_url, self_token ){
                            instance.modules.load( opts['mods'] ) {
                                instance.plugins.load( opts['plugins'] ) {
                                    instance.framework.run {
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
