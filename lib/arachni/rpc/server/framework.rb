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

require Options.instance.dir['lib'] + 'framework'
require Options.instance.dir['lib'] + 'rpc/server/module/manager'
require Options.instance.dir['lib'] + 'rpc/server/plugin/manager'

module RPC
class Server

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
class Framework < ::Arachni::Framework

    include Arachni::Module::Utilities

    # make this inherited methods visible again
    private :audit_store, :stats, :paused?, :lsmod, :lsplug, :version, :revision
    public  :audit_store, :stats, :paused?, :lsmod, :lsplug, :version, :revision

    alias :old_clean_up! :clean_up!
    alias :auditstore    :audit_store

    private :old_clean_up!

    attr_reader :instances, :opts, :modules, :plugins

    MAX_CONCURRENCY = 20
    MIN_PAGES_PER_INSTANCE = 30

    def initialize( opts )
        super( opts )

        @modules = Arachni::RPC::Server::Module::Manager.new( opts )
        @plugins = Arachni::RPC::Server::Plugin::Manager.new( self )

        # holds all running instances
        @instances = []

        @crawling_done = nil
        @override_sitemap = []

        # if we're a slave this var will hold the URL of our master
        @master_url = ''

        @local_token = gen_token
    end

    #
    # Returns the results of the plug-ins
    #
    # @return   [Hash]  plugin name => result
    #
    def get_plugin_store
        @plugin_store
    end

    #
    # Returns true if the system is scanning, false if {#run} hasn't been called yet or
    # if the scan has finished.
    #
    # @param    [Bool]  include_slaves  take slave status into account too? <br/>
    #                                     If so, it will only return false if slaves
    #                                     are done too.
    #
    # @param    [Proc]  &block          block to which to pass the result
    #
    def busy?( include_slaves = true, &block )

        busyness = [ extended_running? ]

        if @instances.empty? || !include_slaves
            block.call( busyness[0] ) if block_given?
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
    # Returns an array containing information about all available plug-ins.
    #
    # @return    [Array<Hash>]
    #
    def lsplug
        plug_info = []

        super.each {
            |plugin|

            plugin[:options] = [plugin[:options]].flatten.compact.map {
                |opt|
                opt.to_h.merge( 'type' => opt.type )
            }

            plug_info << plugin
        }

        return plug_info
    end

    #
    # Returns true if running in HPG (High Performance Grid) mode and we're the master,
    # false otherwise.
    #
    # @return   [Bool]
    #
    def high_performance?
        @opts.grid_mode == 'high_performance'
    end

    #
    # Starts the audit.
    #
    # @return   [Bool]  false if already running, true otherwise
    #
    def run
        # return if we're already running
        return false if extended_running?

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

        @extended_running = true
        ::EM.defer {

            #
            # if we're in HPG mode do fancy stuff like distributing and balancing workload
            # as well as starting slave instances and deal with some lower level
            # operations of the local instance like running plug-ins etc...
            #
            # otherwise just run the local instance, nothing special...
            #
            if high_performance?

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
                prepare

                # we need to take our cues from the local framework as some
                # plug-ins may need the system to wait for them to finish
                # before moving on.
                sleep( 0.2 ) while paused?

                # start the crawl and extract all paths
                Arachni::Spider.new( @opts ).run {
                    |page|
                    @override_sitemap << page.url
                    pages[page.url] = page
                }
                @crawling_done = true

                # the plug-ins may have update the framework page queue
                # so we need to distribute these pages as well
                page_a = []
                page_q = @page_queue
                while !page_q.empty? && page = page_q.pop
                    page_a << page
                    pages[page.url] = page
                end

                # get the Dispatchers with unique Pipe IDs
                # in order to take advantage of line aggregation
                prefered_dispatchers {
                    |pref_dispatchers|

                    # split the URLs of the pages in equal chunks
                    chunks    = split_urls( pages.keys, pref_dispatchers )
                    chunk_cnt = chunks.size

                    if chunk_cnt > 0
                        # split the page array into chunks that will be distributed
                        # across the instances
                        page_chunks = page_a.chunk( chunk_cnt )

                        # assign us our fair share of plug-in discovered pages
                        update_page_queue!( page_chunks.pop, @local_token )

                        # remove duplicate elements across the (per instance) chunks
                        # while spreading them out evenly
                        elements = distribute_elements( chunks, pages )

                        # empty out the Hash and remove temporary files
                        pages.clear

                        # restrict the local instance to its assigned elements
                        restrict_to_elements!( elements.pop, @local_token )

                        # set the URLs to be audited by the local instance
                        @opts.restrict_paths = chunks.pop

                        chunks.each_with_index {
                            |chunk, i|

                            # spawn a remote instance, assign a chunk of URLs
                            # and elements to it and run it
                            spawn( chunk, page_chunks[i], elements[i], pref_dispatchers[i] ) {
                                |inst|
                                @instances << inst
                            }
                        }
                    end

                    # start the local instance
                    Thread.new {
                        # ap 'AUDITING'
                        audit

                        # ap 'OLD CLEAN UP'
                        old_clean_up!

                        # ap 'DONE'
                        @extended_running = false
                    }
                }
            else
                # start the local instance
                Thread.new {
                    # ap 'AUDITING'
                    super
                    # ap 'DONE'
                    @extended_running = false
                }
            end
        }

        return true
    end

    #
    # If the scan needs to be aborted abruptly this method takes care of
    # any unfinished business (like running plug-ins).
    #
    # Should be called before grabbing the {#auditstore}, especially when
    # running in HPG mode as it will take care of merging the plug-in results
    # of all instances.
    #
    # @param    [Proc]  &block  block to be called once the cleanup has finished
    #
    def clean_up!( &block )
        old_clean_up!( true )

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
                    iter.return( !res.rpc_exception? ?  res : nil )
                }
            }

        }, proc {
            |results|
            results.compact!
            results << get_plugin_store
            update_plugin_results!( results )
            block.call
        })
    end

    #
    # Pauses the running scan on a best effort basis.
    #
    def pause!
        super
        ::EM::Iterator.new( @instances, @instances.size ).each {
            |instance, iter|
            connect_to_instance( instance ).framework.pause!{ iter.next }
        }
        return true
    end

    #
    # Resumes a paused scan right away.
    #
    def resume!
        super
        ::EM::Iterator.new( @instances, @instances.size ).each {
            |instance, iter|
            connect_to_instance( instance ).framework.resume!{ iter.next }
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
    # Returns the merged output of all running instances.
    #
    # This is going probably to be wildly out of sync and lack A LOT of messages.
    #
    # It's here to give the notion of scan progress to the end-user rather than
    # provide an accurate depiction of the actual progress.
    #
    # @param    [Proc]  &block  block to which to pass the result
    #
    def output( &block )

        buffer = flush_buffer

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
        if( !@crawling_done && master.empty? && high_performance?) ||
            ( master.empty? && !high_performance? && stats[:current_page].empty? )
            return 'crawling'
        elsif paused?
            return 'paused'
        elsif !extended_running?
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
    # @param    [Hash]  opts    contains info about what data to return:
    #                             * :messages -- include output messages
    #                             * :slaves   -- include slave data
    #                             * :issues   -- include issue summaries
    #                             Uses an implicit include for the above (i.e. nil will be considered true).
    #
    #                             * :as_hash  -- if set to true will convert issues to hashes before returning
    #
    # @param    [Proc]  &block  block to which to pass the result
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

        if opts[:as_hash]
            as_hash = true
        else
            as_hash = opts[:as_hash]
        end

        data = {
            'stats'     => {},
            'status'    => status,
            'busy'      => extended_running?
        }

        data['messages']  = flush_buffer if include_messages

        if include_issues
            data['issues'] = as_hash ? issues_as_hash : issues
        end

        data['instances'] = {} if include_slaves

        stats = []
        stat_hash = {}
        stats( true, true ).each {
            |k, v|
            stat_hash[k.to_s] = v
        }

        if @opts.datastore[:dispatcher_url] && include_slaves
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
                if !tmp.rpc_exception?
                    tmp['url'] = instance['url']
                    iter.return( tmp )
                else
                    iter.return( nil )
                end
            }
        }, proc {
            |slave_data|

            slave_data.compact!
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
    # Returns the results of the audit as a hash.
    #
    # @return   [Hash]
    #
    def report
        audit_store.to_h
    end
    alias :audit_store_as_hash :report
    alias :auditstore_as_hash :report

    #
    # @return   [String]    YAML representation of {#auditstore}
    #
    def serialized_auditstore
        audit_store.to_yaml
    end

    #
    # @return   [String]    YAML representation of {#report}
    #
    def serialized_report
        audit_store.to_h.to_yaml
    end

    #
    # Returns a array containing summaries of all discovered issues (i.e. no variations).
    #
    # @return   [Array<Arachni::Issue>]
    #
    def issues
        audit_store.issues.map {
            |issue|
            tmp_issue = issue.deep_clone
            tmp_issue.variations = []
            tmp_issue
        }
    end

    #
    # Returns the return value of {#issues} as an Array of hashes
    #
    # @return   [Array<Hash>]
    #
    # @see #issues
    #
    def issues_as_hash
        issues.map { |i| i.to_h }
    end

    #
    # The following methods need to be accessible over RPC but are *privileged*.
    #
    # They're used for intra-Grid communication between masters and their slaves
    #
    #

    #
    # Restricts the scope of the audit to individual elements.
    #
    # @param    [Array]     elements    list of element IDs
    # @param    [String]    token       privileged token, prevents this method
    #                                       from being called by 3rd parties.
    #
    # @return   [Bool]  true on success, false on invalid token
    #
    def restrict_to_elements!( elements, token = nil )
        return false if high_performance? && !valid_token?( token )

        ::Arachni::Element::Auditable.restrict_to_elements!( elements )
        return true
    end

    #
    # Sets the URL and authentication token required to connect to our master.
    #
    # @param    [String]    url     master's URL in 'hostname:port' form
    # @param    [String]    token   master's authentication token
    #
    # @return   [Bool]  true on success, false if this is the master of the HPG
    #                       (in which case this is not applicable).
    #
    def set_master( url, token )
        return false if high_performance?

        @master_url = url
        @master = connect_to_instance( { 'url' => url, 'token' => token } )

        @modules.class.do_not_store!
        @modules.class.on_register_results {
            |results|
            report_issues_to_master( results )
        }

        return true
    end

    #
    # Updates the page queue with the provided pages.
    #
    # @param    [Array]     pages       list of pages
    # @param    [String]    token       privileged token, prevents this method
    #                                       from being called by 3rd parties.
    #
    # @return   [Bool]  true on success, false on invalid token
    #
    def update_page_queue!( pages, token = nil )
        return false if high_performance? && !valid_token?( token )
        pages.each { |page| @page_queue << page }
        return true
    end

    #
    # Registers an array holding {Arachni::Issue} objects with the local instance.
    #
    # Primarily used by slaves to register issues they find on the spot.
    #
    # @param    [Array<Arachni::Issue>]    issues
    # @param    [String]                   token     privileged token, prevents this method
    #                                                   from being called by 3rd parties.
    #
    # @return   [Bool]  true on success, false on invalid token or if not in HPG mode
    #
    def register_issues( issues, token )
        return false if high_performance? && !valid_token?( token )

        @modules.class.register_results( issues )
        return true
    end

    private

    def extended_running?
        @extended_running
    end

    def valid_token?( token )
        @local_token == token
    end

    def set_plugin_store( plugin_store )
        @plugin_store = plugin_store
    end

    #
    # Connects to a remote Instance.
    #
    # @param    [Hash]  instance    the hash must hold the 'url' and the 'token'.
    #                                   In subsequent calls the 'token' can be omitted.
    #
    def connect_to_instance( instance )
        @tokens  ||= {}

        @tokens[instance['url']] = instance['token'] if instance['token']
        Arachni::RPC::Client::Instance.new( @opts, instance['url'], @tokens[instance['url']] )
    end

    #
    # Reports an array of issues back to the master instance.
    #
    # @param    [Array<Arachni::Issue>]     issues
    #
    def report_issues_to_master( issues )
        @master.framework.register_issues( issues, master_priv_token ){}
        return true
    end

    #
    # Takes the plug-in results of all the instances, merges them together and
    # resets the @plugin_store.
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

        set_plugin_store( merged )
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

        if @opts.audit_links
            list |= page.links.map { |elem| elem.audit_id( nil, opts ) }.uniq
        end

        if @opts.audit_forms
            list |= page.forms.map { |elem| elem.audit_id( nil, opts ) }.uniq
        end

        if @opts.audit_cookies
            list |= page.cookies.map { |elem| elem.audit_id( nil, opts ) }.uniq
        end

        return list
    end

    #
    # Returns the dispatchers that have different Pipe IDs i.e. can be setup
    # in HPG mode; pretty simple at this point.
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
                    connect_to_dispatcher( dispatcher['url'] ).stats {
                        |res|
                        if !res.rpc_exception?
                            iter.return( res )
                        else
                            iter.return( nil )
                        end
                    }
                }, proc {
                    |dispatchers|

                    # get the Dispatchers with unique Pipe IDs and send them
                    # to the block

                    pref_dispatcher_urls = []
                    pick_dispatchers( dispatchers ).each {
                        |dispatcher|
                        if !@used_pipe_ids.include?( dispatcher['node']['pipe_id'] )
                            @used_pipe_ids << dispatcher['node']['pipe_id']
                            pref_dispatcher_urls << dispatcher['node']['url']
                        end
                    }

                    block.call( pref_dispatcher_urls )
                })
            }
        }
    end

    #
    # Splits URLs into chunks for each instance while taking into account a
    # minimum amount of URLs per instance.
    #
    def split_urls( urls, dispatchers )
        chunks = []
        idx    = 0

        # figure out the min amount of pages per chunk
        begin
            if @opts.min_pages_per_instance && @opts.min_pages_per_instance.to_i > 0
                min_pages_per_instance = @opts.min_pages_per_instance.to_i
            else
                min_pages_per_instance = MIN_PAGES_PER_INSTANCE
            end
        rescue
            min_pages_per_instance = MIN_PAGES_PER_INSTANCE
        end

        # first try a simplistic approach, just split the the URLs in
        # equally sized chunks for each instance
        orig_chunks = urls.chunk( dispatchers.size + 1 )

        # if the first chunk matches the minimum then they all do
        # (except the last possibly) so return these as is...
        return orig_chunks if orig_chunks[0].size >= min_pages_per_instance

        #
        # otherwise re-arrange the chunks into larger ones
        #
        orig_chunks.each.with_index {
            |chunk, i|

            chunk.each {
                |url|

                chunks[idx] ||= []
                if chunks[idx].size < min_pages_per_instance
                    chunks[idx] << url
                else
                    idx += 1
                end
            }
        }

        return chunks
    end

    #
    # Picks the dispatchers to use based on their load balancing metrics and
    # the instructed maximum amount of slaves.
    #
    def pick_dispatchers( dispatchers )
        d = dispatchers.each.with_index {
            |dispatcher, i|
            dispatchers[i]['score'] = get_dispatcher_score( dispatcher )
        }.sort {
            |dispatcher_1, dispatcher_2|
            dispatcher_1['score'] <=> dispatcher_2['score']
        }

        begin
            if @opts.max_slaves && @opts.max_slaves.to_i > 0
                return d[0...@opts.max_slaves.to_i]
            end
        rescue
            return d
        end
    end

    #
    # Returns the load balancing score of a dispatcher based
    # on its resource consumption and weight.
    #
    def get_dispatcher_score( dispatcher )
        score = get_resource_consumption( dispatcher['running_jobs'] )
        score *= dispatcher['weight'] if dispatcher['weight']
        return score
    end

    #
    # Returns a nominal resource consumption of a dispatcher.
    #
    # It's basically calculated as the sum of the CPU and Memory usage
    # percentages of its running instances.
    #
    def get_resource_consumption( jobs )
        mem = 0
        cpu = 0
        jobs.each {
            |job|
            mem += Float( job['proc']['pctmem'] ) if job['proc']['pctmem']
            cpu += Float( job['proc']['pctcpu'] ) if job['proc']['pctcpu']
        }

        return cpu + mem
    end

    #
    # Spawns and runs a new remote instance
    #
    def spawn( urls, pages, elements, prefered_dispatcher, &block )

        opts = @opts.to_h.deep_clone

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

            opts['datastore']['master_priv_token'] = @local_token

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
                instance.framework.update_page_queue!( pages ) {
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

        port = @opts.rpc_port
        d_port = @opts.datastore[:dispatcher_url].split( ':', 2 )[1]
        @self_url = @opts.datastore[:dispatcher_url].gsub( d_port, port.to_s )
    end

    def master_priv_token
        @opts.datastore['master_priv_token']
    end

    def gen_token
        Digest::SHA2.hexdigest( 10.times.map{ rand( 9999 ) }.join( '' ) )
    end

    def dispatcher
       connect_to_dispatcher( @opts.datastore[:dispatcher_url] )
    end

    def connect_to_dispatcher( url )
        Arachni::RPC::Client::Dispatcher.new( @opts, url )
    end

    def merge_stats( stats )
        final_stats = stats.pop.dup
        return {} if !final_stats || final_stats.empty?

        return final_stats if stats.empty?

        final_stats['current_pages'] = []
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

                final_stats['eta'] ||= instats['eta']
                final_stats['eta']   = max_eta( final_stats['eta'], instats['eta'] )
            }

            avg.each {
                |k|
                final_stats[k.to_s] /= Float( stats.size + 1 )
                final_stats[k.to_s] = Float( sprintf( "%.2f", final_stats[k.to_s] ) )
            }
        rescue Exception => e
            # ap e
            # ap e.backtrace
        end

        final_stats['sitemap_size'] = @override_sitemap.size

        return final_stats
    end

    def max_eta( eta1, eta2 )
        return eta1 if eta1 == eta2

        # splits them into hours, mins and secs
        eta1_splits = eta1.split( ':' )
        eta2_splits = eta2.split( ':' )

        # go through and compare the hours, mins, sec
        eta1_splits.size.times {
            |i|
            return eta1 if eta1_splits[i].to_i > eta2_splits[i].to_i
            return eta2 if eta1_splits[i].to_i < eta2_splits[i].to_i
        }
    end

end

end
end
end
