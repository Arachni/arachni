=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

require 'em-synchrony'
require 'tempfile'

module Arachni

lib = Options.dir['lib']
require lib + 'buffer'
require lib + 'framework'
require lib + 'rpc/server/spider'
require lib + 'rpc/server/module/manager'
require lib + 'rpc/server/plugin/manager'

module RPC
class Server

#
# Wraps the framework of the local instance and the frameworks of all its slaves
# (when it is as Master in High Performance Grid mode) into a neat, easy to
# handle package.
#
# @note Ignore:
#
#   * Inherited methods and attributes -- only public methods of this class are
#       accessible over RPC.
#   * `block` parameters, they are an RPC implementation detail for methods which
#       perform asynchronous operations.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Framework < ::Arachni::Framework
    require Options.dir['lib'] + 'rpc/server/distributor'

    include Utilities
    include Distributor

    #
    # {RPC::Server::Framework} error namespace.
    #
    # All {RPC::Server::Framework} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    #
    class Error < Arachni::Framework::Error

        #
        # Raised when an option is nor supported for whatever reason.
        #
        # For example, {Options#restrict_paths} isn't supported when in
        # HPG mode.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        #
        class UnsupportedOption < Error
        end
    end

    # Make these inherited methods public again (i.e. accessible over RPC).
    [ :audit_store, :stats, :paused?, :lsmod, :list_modules, :lsplug,
      :list_plugins, :lsrep, :list_reports, :version, :revision, :status,
      :clean_up!, :report_as ].each do |m|
        private m
        public m
    end

    alias :auditstore :audit_store

    # Buffer issues and only report them to the master instance when the buffer
    # reaches (or exceeds) this size.
    ISSUE_BUFFER_SIZE = 100

    # How many times to try and fill the issue buffer before flushing it.
    ISSUE_BUFFER_FILLUP_ATTEMPTS = 10

    def initialize( opts )
        super( opts )

        # already inherited but lets make it explicit
        @opts = opts

        # Override standard framework components with their RPC-server
        # counterparts.
        @modules = Module::Manager.new( self )
        @plugins = Plugin::Manager.new( self )
        @spider  = Spider.new( self )

        # holds all running instances
        @instances = []

        # if we're a slave this var will hold the URL of our master
        @master_url = ''

        # some methods need to be accessible over RPC for instance management,
        # restricting elements, adding more pages etc.
        #
        # however, when in HPG mode, the master should not be tampered with,
        # so we generate a local token (which is not known to API clients)
        # to be used server side by self to facilitate access control
        @local_token = gen_token

        @override_sitemap = Set.new
        @local_sitemap    = Set.new

        @element_ids_per_page = {}

        # running slaves
        @running_slaves = Set.new

        # holds instances which have completed their scan
        @done_slaves = Set.new

        @issue_summaries = []
    end

    # @return (see Arachni::Framework#list_plugins)
    def list_plugins
        super.map do |plugin|
            plugin[:options] = [plugin[:options]].flatten.compact.map do |opt|
                opt.to_h.merge( 'type' => opt.type )
            end
            plugin
        end
    end
    alias :lsplug :list_plugins

    # @return (see Arachni::Framework#list_reports)
    def list_reports
        super.map do |report|
            report[:options] = [report[:options]].flatten.compact.map do |opt|
                opt.to_h.merge( 'type' => opt.type )
            end
            report
        end
    end
    alias :lsrep :list_reports

    # @return   [Bool]
    #   `true` If the system is scanning, `false` if {#run} hasn't been called
    #   yet or if the scan has finished.
    def busy?
        !!@extended_running
    end

    #
    # Sets this instance as the master.
    #
    # @return   [Bool]
    #   `true` on success, `false` if this instance is not a {#solo? solo} one.
    #
    def set_as_master
        return false if !solo?
        @opts.grid_mode = 'high_performance'
        true
    end

    # @return   [Bool]
    #   `true` if running in HPG (High Performance Grid) mode and instance is
    #   the master, false otherwise.
    def master?
        @opts.grid_mode == 'high_performance'
    end
    alias :high_performance? :master?

    # @return   [Bool]  `true` if this instance is a slave, `false` otherwise.
    def slave?
        !!@master
    end

    # @return   [Bool]
    #   `true` if this instance is running solo (i.e. not a member of a grid
    #   operation), `false` otherwise.
    def solo?
        !master? && !slave?
    end

    #
    # Enslaves another instance and subsequently becomes the master of the group.
    #
    # @param    [Hash]  instance_info
    #   `{ 'url' => '<host>:<port>', 'token' => 's3cr3t' }`
    #
    # @return   [Bool]
    #   `true` on success, `false` is this instance is a slave (slaves can't
    #   have slaves of their own).
    #
    def enslave( instance_info, opts = {}, &block )
        if slave?
            block.call false
            return false
        end

        instance_info = instance_info.to_hash.
            inject( {} ) { |h, (k, v)| h[k.to_s] = v; h }

        fail "Instance info does not contain a 'url' key."   if !instance_info['url']
        fail "Instance info does not contain a 'token' key." if !instance_info['token']

        # since we have slaves we must be a master...
        set_as_master

        instance = connect_to_instance( instance_info )
        instance.opts.set( cleaned_up_opts ) do
            instance.framework.set_master( self_url, token ) do
                @instances << instance_info
                block.call true if block_given?
            end
        end

        true
    end

    #
    # Starts the scan.
    #
    # @return   [Bool]  `false` if already running, `true` otherwise.
    #
    def run
        # Return if we're already running.
        return false if busy?

        if master? && @opts.restrict_paths.any?
            fail Error::UnsupportedOption,
                 'Option \'restrict_paths\' is not supported when in High-Performance mode.'
        end

        @extended_running = true

        # Prepare the local instance (runs plugins and starts the timer).
        prepare

        #
        # If we're in HPG mode (and we're the master) do fancy stuff like
        # distributing and balancing workload as well as starting slave
        # instances and deal with some lower level operations of the local
        # instance like running plug-ins etc.
        #
        # Otherwise, just run the local instance, nothing special...
        #
        if master?

            # We can't block RPC methods.
            ::Thread.new {

                #
                # We're in HPG (High Performance Grid) mode,
                # things are going to get weird...
                #

                # We'll need analyze the pages prior to assigning
                # them to each instance at the element level so as to gain
                # more granular control over the assigned workload.
                #
                # Put simply, we'll need to perform some magic in order
                # to prevent different instances from auditing the same elements
                # and wasting bandwidth.
                #
                # For example: Search forms, logout links and the like will
                # most likely exist on most pages of the site and since each
                # instance is assigned a set of URLs/pages to audit they will end up
                # with common elements so we have to prevent instances from
                # performing identical checks.
                #
                # Interesting note: Should previously unseen elements dynamically
                # appear during the audit they will override these restrictions
                # and each instance will audit them at will.
                #

                # We need to take our cues from the local framework as some
                # plug-ins may need the system to wait for them to finish
                # before moving on.
                sleep( 0.2 ) while paused?

                # Prepare a block to process each Dispatcher and request
                # slave instances from it.
                each = proc do |d_url, iterator|
                    if ignore_grid?
                        iterator.next
                        next
                    end

                    d_opts = {
                        'rank'   => 'slave',
                        'target' => @opts.url,
                        'master' => self_url
                    }

                    connect_to_dispatcher( d_url ).
                        dispatch( self_url, d_opts ) do |instance_hash|
                            enslave( instance_hash ){ |b| iterator.next }
                        end
                end

                # Prepare a block to process the slave instances and start the scan.
                after = proc do
                    @status = :crawling

                    spider.on_each_page do |page|

                        # We need to restrict the scope of our audit to the
                        # pages our crawler discovered.
                        update_element_ids_per_page(
                            { page.url => build_elem_list( page ) },
                            @local_token
                        )

                        @local_sitemap << page.url
                    end

                    spider.on_complete do

                        # Start building a whitelist of elements using their IDs.
                        element_ids_per_page = @element_ids_per_page

                        @override_sitemap |= spider.sitemap


                        # Guess what we're doing now...
                        @status = :distributing

                        # The plug-ins may have updated the page queue so we
                        # need to take these pages into account as well.
                        page_a = []
                        while !@page_queue.empty? && page = @page_queue.pop
                            page_a << page
                            @override_sitemap << page.url
                            element_ids_per_page[page.url] |= build_elem_list( page )
                        end

                        # Split the URLs of the pages in equal chunks.
                        chunks    = split_urls( element_ids_per_page.keys,
                                                @instances.size + 1 )
                        chunk_cnt = chunks.size

                        if chunk_cnt > 0
                            # Split the page array into chunks that will be
                            # distributed across the instances.
                            page_chunks = page_a.chunk( chunk_cnt )

                            # Assign us our fair share of plug-in discovered pages.
                            update_page_queue( page_chunks.pop, @local_token )

                            # Remove duplicate elements across the (per instance)
                            # chunks while spreading them out evenly.
                            elements = distribute_elements( chunks,
                                                            element_ids_per_page )

                            # Restrict the local instance to its assigned elements.
                            restrict_to_elements( elements.pop, @local_token )

                            # Set the URLs to be audited by the local instance.
                            @opts.restrict_paths = chunks.pop

                            chunks.each_with_index do |chunk, i|
                                # Distribute the audit workload tell the slaves
                                # to have at it.
                                distribute_and_run( @instances[i],
                                                   urls:     chunk,
                                                   elements: elements.pop,
                                                   pages:    page_chunks.pop
                                )
                            end
                        end

                        # Start the local instance's audit.
                        Thread.new {
                            audit

                            @finished_auditing = true

                            cleanup_if_all_done
                        }
                    end

                    # Let crawlers know of each other and start the scan.
                    spider.update_peers( @instances ){ spider.run }
                end

                # Get the Dispatchers with unique Pipe IDs
                # in order to take advantage of line aggregation.
                preferred_dispatchers do |pref_dispatchers|
                    iterator_for( pref_dispatchers ).each( each, after )
                end

            }
        else
            # Start the local instance (we can't block the RPC that's why we're
            # using a Thread).
            Thread.new {
                audit

                if slave?
                    # Make sure we've reported all issues back to the master.
                    flush_issue_buffer do
                        @master.framework.slave_done( self_url, master_priv_token ) do
                            @extended_running = false
                        end
                    end
                else
                    @extended_running = false
                    clean_up
                    @status = :done
                end
            }
        end

        true
    end

    #
    # If the scan needs to be aborted abruptly this method takes care of
    # any unfinished business (like signaling running plug-ins to finish).
    #
    # Should be called before grabbing the {#auditstore}, especially when
    # running in HPG mode as it will take care of merging the plug-in results
    # of all instances.
    #
    # You don't need to call this if you've let the scan complete.
    #
    def clean_up( &block )
        if @cleaned_up
            block.call false
            return false
        end
        @cleaned_up = true

        r = super

        return r if !block_given?

        if @instances.empty?
            block.call r if block_given?
            return r
        end

        foreach = proc do |instance, iter|
            instance.framework.clean_up {
                instance.plugins.results do |res|
                    iter.return( !res.rpc_exception? ? res : nil )
                end
            }
        end
        after = proc { |results| @plugins.merge_results( results.compact ); block.call( true ) }
        map_slaves( foreach, after )
    end

    # Pauses the running scan on a best effort basis.
    def pause( &block )
        r = super
        return r if !block_given?

        each = proc { |instance, iter| instance.framework.pause { iter.next } }
        each_slave( each, proc { block.call true } )
    end
    alias :pause! :pause

    # Resumes a paused scan right away.
    def resume( &block )
        r = super
        return r if !block_given?

        each = proc { |instance, iter| instance.framework.resume { iter.next } }
        each_slave( each, proc { block.call true } )
    end
    alias :resume! :resume

    #
    # Merged output of all running instances.
    #
    # This is going to be wildly out of sync and lack A LOT of messages.
    #
    # It's here to give the notion of progress to the end-user rather than
    # provide an accurate depiction of the actual progress.
    #
    # The returned object will be in the form of:
    #
    #   [ { <type> => <message> } ]
    #
    # like:
    #
    #   [
    #       { status: 'Initiating'},
    #       {   info: 'Some informational msg...'},
    #   ]
    #
    # Possible message types are:
    # * `status`  -- Status messages, usually to denote progress.
    # * `info`  -- Informational messages, like notices.
    # * `ok`  -- Denotes a successful operation or a positive result.
    # * `verbose` -- Verbose messages, extra information about whatever.
    # * `bad`  -- Opposite of :ok, an operation didn't go as expected,
    #   something has failed but it's recoverable.
    # * `error`  -- An error has occurred, this is not good.
    # * `line`  -- Generic message, no type.
    #
    # @return   [Array<Hash>]
    #
    # @deprecated
    #
    def output( &block )
        buffer = flush_buffer

        if @instances.empty?
            block.call( buffer )
            return
        end

        foreach = proc do |instance, iter|
            instance.service.output { |out| iter.return( out ) }
        end
        after = proc { |out| block.call( (buffer | out).flatten ) }
        map_slaves( foreach, after )
    end

    # @see Arachni::Framework#stats
    def stats( *args )
        ss = super( *args )
        ss.tap { |s| s[:sitemap_size] = @local_sitemap.size } if !solo?
        ss
    end

    #
    # @param    [Integer]   starting_line
    #   Sets the starting line for the range of errors to return.
    #
    # @return   [Array<String>]
    #
    def errors( starting_line = 0, &block )
        return [] if !File.exists? error_logfile

        error_strings = IO.read( error_logfile ).split( "\n" )

        if starting_line != 0
            error_strings = error_strings[starting_line..-1]
        end

        return error_strings if !block_given?

        if @instances.empty?
            block.call( error_strings )
            return
        end

        foreach = proc do |instance, iter|
            instance.framework.errors( starting_line ) { |errs| iter.return( errs ) }
        end
        after = proc { |out| block.call( (error_strings | errs).flatten ) }
        map_slaves( foreach, after )
    end


    #
    # Returns aggregated progress data and helps to limit the amount of calls
    # required in order to get an accurate depiction of a scan's progress and includes:
    #
    # * output messages
    # * discovered issues
    # * overall statistics
    # * overall scan status
    # * statistics of all instances individually
    #
    # @param    [Hash]  opts    Options about what data to include:
    # @option opts [Bool] :messages (true) Output messages.
    # @option opts [Bool] :slaves   (true) Slave statistics.
    # @option opts [Bool] :issues   (true) Issue summaries.
    # @option opts [Bool] :stats   (true) Master/merged statistics.
    # @option opts [Integer] :errors   (false) Logged errors.
    # @option opts [Bool] :as_hash  (false)
    #   If set to `true`, will convert issues to hashes before returning them.
    #
    # @return    [Hash]  Progress data.
    #
    def progress( opts = {}, &block )
        include_stats    = opts[:stats].nil? ? true : opts[:stats]
        include_messages = opts[:messages].nil? ? true : opts[:messages]
        include_slaves   = opts[:slaves].nil? ? true : opts[:slaves]
        include_issues   = opts[:issues].nil? ? true : opts[:issues]
        include_errors   = opts.include?( :errors ) ? (opts[:errors] || 0) : false

        as_hash = opts[:as_hash] ? true : opts[:as_hash]

        data = {
            'stats'  => {},
            'status' => status,
            'busy'   => running?
        }

        data['messages']  = flush_buffer if include_messages

        if include_errors
            data['errors'] = errors( include_errors.is_a?( Integer ) ? include_errors : 0 )
        end

        if include_issues
            data['issues'] = as_hash ? issues_as_hash : issues
        end

        data['instances'] = {} if include_slaves

        stats = []
        stat_hash = {}
        stats( true, true ).each { |k, v| stat_hash[k.to_s] = v } if include_stats

        if master? && include_slaves
            data['instances'][self_url] = stat_hash.dup
            data['instances'][self_url]['url'] = self_url
            data['instances'][self_url]['status'] = status
        end

        stats << stat_hash

        if @instances.empty? || !include_slaves
            if include_stats
                data['stats'] = merge_stats( stats )
            else
                data.delete( 'stats' )
            end
            data['instances'] = data['instances'].values if include_slaves
            block.call( data )
            return
        end

        foreach = proc do |instance, iter|
            instance.framework.progress_data( opts ) do |tmp|
                if !tmp.rpc_exception?
                    tmp['url'] = instance.url
                    iter.return( tmp )
                else
                    iter.return( nil )
                end
            end
        end

        after = proc do |slave_data|
            slave_data.compact!
            slave_data.each do |slave|
                data['messages'] |= slave['messages'] if include_messages
                data['issues']   |= slave['issues'] if include_issues
                data['errors']   |= slave['errors'] if include_errors

                if include_slaves
                    url = slave['url']
                    data['instances'][url]           = slave['stats'] || {}
                    data['instances'][url]['url']    = url
                    data['instances'][url]['status'] = slave['status']
                end

                stats << slave['stats']
            end

            if include_slaves
                sorted_data_instances = {}
                data['instances'].keys.sort.each do |url|
                    sorted_data_instances[url] = data['instances'][url]
                end
                data['instances'] = sorted_data_instances.values
            end

            if include_stats
                data['stats'] = merge_stats( stats )
            else
                data.delete( 'stats' )
            end

            data['busy']  = slave_data.map { |d| d['busy'] }.include?( true )

            block.call( data )
        end

        map_slaves( foreach, after )
    end
    alias :progress_data :progress

    # @return   [Hash]  Audit results as a {AuditStore#to_h hash}.
    # @see AuditStore#to_h
    def report
        audit_store.to_h
    end
    alias :audit_store_as_hash :report
    alias :auditstore_as_hash :report

    # @return   [String]    YAML representation of {#report}.
    def serialized_report
        report.to_yaml
    end

    # @return   [String]    YAML representation of {#auditstore}.
    def serialized_auditstore
        audit_store.to_yaml
    end

    # @return  [Array<Arachni::Issue>]
    #   First variations of all discovered issues.
    def issues
        (auditstore.issues.deep_clone.map do |issue|
            issue.variations.first || issue
        end) | @issue_summaries
    end

    # @return   [Array<Hash>]   {#issues} as an array of Hashes.
    # @see #issues
    def issues_as_hash
        issues.map( &:to_h )
    end

    #
    # Updates the page queue with the provided pages.
    #
    # @param    [Array<Arachni::Page>]     pages   List of pages.
    # @param    [String]    token
    #   Privileged token, prevents this method from being called by 3rd parties
    #   when this instance is a master. If this instance is not a master one
    #   the token needn't be provided.
    #
    # @return   [Bool]  `true` on success, `false` on invalid `token`.
    #
    def update_page_queue( pages, token = nil )
        return false if master? && !valid_token?( token )
        [pages].flatten.each { |page| push_to_page_queue( page )}
        true
    end

    #
    # The following methods need to be accessible over RPC but are *privileged*.
    #
    # They're used for intra-Grid communication between masters and their slaves
    #

    #
    # Restricts the scope of the audit to individual elements.
    #
    # @param    [Array<String>]     elements
    #   List of element IDs (as created by
    #   {Arachni::Element::Capabilities::Auditable#scope_audit_id}).
    #
    # @param    [String]    token
    #   Privileged token, prevents this method from being called by 3rd parties
    #   when this instance is a master. If this instance is not a master one
    #   the token needn't be provided.
    #
    # @return   [Bool]  `true` on success, `false` on invalid `token`.
    #
    # @private
    #
    def restrict_to_elements( elements, token = nil )
        return false if master? && !valid_token?( token )
        Element::Capabilities::Auditable.restrict_to_elements( elements )
        true
    end

    #
    # Used by slave crawlers to update the master's list of element IDs per URL.
    #
    # @param    [Hash]     element_ids_per_page
    #   List of element IDs (as created by
    #   {Arachni::Element::Capabilities::Auditable#scope_audit_id}) for each
    #   page (by URL).
    #
    # @param    [String]    token
    #   Privileged token, prevents this method from being called by 3rd parties
    #   when this instance is a master. If this instance is not a master one
    #   the token needn't be provided.
    #
    # @return   [Bool]  `true` on success, `false` on invalid `token`.
    #
    # @private
    #
    def update_element_ids_per_page( element_ids_per_page = {}, token = nil,
                                     signal_done_peer_url = nil )
        return false if master? && !valid_token?( token )

        element_ids_per_page.each do |url, ids|
            @element_ids_per_page[url] ||= []
            @element_ids_per_page[url] |= ids
        end

        if signal_done_peer_url
            spider.peer_done signal_done_peer_url
        end

        true
    end

    #
    # Signals that a slave has finished auditing -- each slave must call this
    # when it finishes its job.
    #
    # @param    [String]    slave_url   URL of the calling slave.
    # @param    [String]    token
    #   Privileged token, prevents this method from being called by 3rd parties
    #   when this instance is a master. If this instance is not a master one
    #   the token needn't be provided.
    #
    # @return   [Bool]  `true` on success, `false` on invalid `token`.
    #
    # @private
    #
    def slave_done( slave_url, token = nil )
        return false if master? && !valid_token?( token )
        @done_slaves << slave_url

        cleanup_if_all_done
        true
    end

    #
    # Registers an array holding {Arachni::Issue} objects with the local instance.
    #
    # Used by slaves to register the issues they find.
    #
    # @param    [Array<Arachni::Issue>]    issues
    # @param    [String]    token
    #   Privileged token, prevents this method from being called by 3rd parties
    #   when this instance is a master. If this instance is not a master one
    #   the token needn't be provided.
    #
    # @return   [Bool]  `true` on success, `false` on invalid `token`.
    #
    # @private
    #
    def register_issues( issues, token = nil )
        return false if master? && !valid_token?( token )
        @modules.class.register_results( issues )
        true
    end

    #
    # Registers an array holding stripped-out {Arachni::Issue} objects
    # with the local instance.
    #
    # Used by slaves to register their issues (without response bodies and other
    # largish data sets) with the master right away while buffering the complete
    # issues to be transmitted in batches later for better bandwidth utilization.
    #
    # These summary issues are to be included in {#issues} in order for the master
    # to have accurate live data to present to the client.
    #
    # @param    [Array<Arachni::Issue>]    issues
    # @param    [String]    token
    #   Privileged token, prevents this method from being called by 3rd parties
    #   when this instance is a master. If this instance is not a master one
    #   the token needn't be provided.
    #
    # @return   [Bool]  `true` on success, `false` on invalid `token`.
    #
    # @private
    #
    def register_issue_summaries( issues, token = nil )
        return false if master? && !valid_token?( token )
        @issue_summaries |= issues
        true
    end

    #
    # Sets the URL and authentication token required to connect to the
    # instance's master.
    #
    # @param    [String]    url     Master's URL in `hostname:port` form.
    # @param    [String]    token   Master's authentication token.
    #
    # @return   [Bool]
    #   `true` on success, `false` if the current instance is already part of
    #   the grid.
    #
    # @private
    #
    def set_master( url, token )
        return false if !solo?

        # make sure the desired plugins are loaded before #prepare runs them
        plugins.load @opts.plugins if @opts.plugins

        prepare

        @master_url = url
        @master = connect_to_instance( 'url' => url, 'token' => token )

        @slave_element_ids_per_page ||= {}

        @elem_ids_filter ||= Arachni::BloomFilter.new

        spider.on_each_page do |page|
            @status = :crawling

            @local_sitemap << page.url

            ids = build_elem_list( page ).reject do |id|
                if @elem_ids_filter.include? id
                    true
                else
                    @elem_ids_filter << id
                    false
                end
            end

            next if ids.empty?

            @slave_element_ids_per_page[page.url] = ids.map { |i| i }
        end

        spider.after_each_run do
            if !@slave_element_ids_per_page.empty?
                @master.framework.
                    update_element_ids_per_page( @slave_element_ids_per_page.dup,
                                               master_priv_token,
                                               spider.done? ? self_url : false ){}

                @slave_element_ids_per_page.clear
            else
                spider.signal_if_done( @master )
            end
        end

        # buffers logged issues that are to be sent to the master
        @issue_buffer = Buffer::AutoFlush.new( ISSUE_BUFFER_SIZE,
                                               ISSUE_BUFFER_FILLUP_ATTEMPTS )

        @issue_buffer.on_flush { |buffer| send_issues_to_master( buffer ) }

        # don't store issues locally
        @modules.do_not_store

        @modules.on_register_results do |issues|
            # Only send summaries of the issues to the master right away so that
            # the the master will have live data to show the user...
            send_issue_summaries_to_master issues

            # ...but buffer the complete issues to be sent in batches for better
            # bandwidth utilization.
            @issue_buffer.batch_push issues
        end
        true
    end

    # @return   [String]  URL of this instance.
    # @private
    def self_url
        @self_url ||= "#{@opts.rpc_address}:#{@opts.rpc_port}"
    end

    # @private
    def ignore_grid
        @ignore_grid = true
    end

    # @return   [String]  This instance's RPC token.
    def token
        @opts.datastore[:token]
    end

    # @private
    def error_test( str )
        print_error str.to_s
    end

    private

    def ignore_grid?
        !!@ignore_grid
    end

    def prepare
        return if @prepared
        super
        @prepared = true
    end

    def cleanup_if_all_done
        return if !@finished_auditing || @running_slaves != @done_slaves

        # we pass a block because we want to perform a grid cleanup,
        # not just a local one
        clean_up do
            @extended_running = false
            @status = :done
        end
    end

    def auditstore_sitemap
        @override_sitemap | @sitemap
    end

    def valid_token?( token )
        @local_token == token
    end

    #
    # Reports an array of issues back to the master instance.
    #
    # @param    [Array<Arachni::Issue>]     issues
    #
    def report_issues_to_master( issues )
        @issue_buffer.batch_push issues
        true
    end

    def flush_issue_buffer( &block )
        send_issues_to_master( @issue_buffer.flush ){ block.call if block_given? }
    end

    def send_issues_to_master( issues, &block )
        @master.framework.register_issues( issues,
                                           master_priv_token
        ){ block.call if block_given? }
    end

    def send_issue_summaries_to_master( issues, &block )
        @unique_issue_summaries ||= Set.new

        # Multiple variations for grep modules are not being filtered when
        # an issue is registered, and for good reason; however, we do need to filter
        # them in this case since we're summarizing.
        summaries = AuditStore.new( issues: issues ).issues.map do |i|
            next if @unique_issue_summaries.include?( i.unique_id )
            di = i.deep_clone
            di.variations.first || di
        end.compact

        @unique_issue_summaries |= summaries.each { |issue| issue.unique_id }

        @master.framework.register_issue_summaries( summaries,
                                           master_priv_token
        ){ block.call if block_given? }
    end

    def master_priv_token
        @opts.datastore['master_priv_token']
    end

    def gen_token
        Digest::SHA2.hexdigest( 10.times.map{ rand( 9999 ) }.join )
    end

end

end
end
end
