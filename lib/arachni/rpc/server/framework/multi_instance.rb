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

module Arachni
class RPC::Server::Framework

#
# Holds multi-Instance methods for the {RPC::Server::Framework}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module MultiInstance
    include Distributor

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
        # Slaves can't have slaves of their own.
        if slave?
            block.call false
            return false
        end

        instance_info = instance_info.symbolize_keys

        fail "Instance info does not contain a 'url' key."   if !instance_info[:url]
        fail "Instance info does not contain a 'token' key." if !instance_info[:token]

        # Since we have slaves we must be a master.
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
    # They're used for intra-Grid/inter-Instance communication between masters
    # and their slaves
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

        @element_ids_per_page ||= {}
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
    # Sets the URL and authentication token required to connect to this
    # Instance's master.
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

        # Make sure the desired plugins are loaded before #prepare runs them.
        plugins.load @opts.plugins if @opts.plugins

        # Start the clock and run the plugins.
        prepare

        @master_url = url
        @master     = connect_to_instance( 'url' => url, 'token' => token )

        # Multi-Instance scans need extra info when it comes to auditing,
        # like a whitelist of elements each slave is allowed to audit.
        #
        # Each slave needs to populate a list of element scope-IDs for each page
        # it finds and send it back to the master, which will determine their
        # distribution when it comes time for the audit.
        #
        # This is our buffer for that list.
        @slave_element_ids_per_page = Hash.new

        # Helps us do some preliminary deduplication on our part to avoid sending
        # over duplicate element IDs.
        @elem_ids_filter = Arachni::BloomFilter.new

        spider.on_each_page do |page|
            @status = :crawling
            @local_sitemap << page.url

            # Build a list of deduplicated element scope IDs for this page.
            @slave_element_ids_per_page[page.url] ||= []
            build_elem_list( page ).each do |id|
                next if @elem_ids_filter.include?( id )
                @elem_ids_filter << id
                @slave_element_ids_per_page[page.url] << id
            end
        end

        spider.after_each_run do
            # Flush our element IDs buffer, if it's not empty...
            if @slave_element_ids_per_page.any?
                @master.framework.update_element_ids_per_page(
                    @slave_element_ids_per_page.dup,
                    master_priv_token,
                    # ...and also let our master know whether or not we're done
                    # crawling.
                    spider.done? ? self_url : false ){}

                @slave_element_ids_per_page.clear
            else
                # Let the master not if we're done crawling.
                spider.signal_if_done @master
            end
        end

        # Buffer for logged issues that are to be sent to the master.
        @issue_buffer = Buffer::AutoFlush.new( ISSUE_BUFFER_SIZE,
                                               ISSUE_BUFFER_FILLUP_ATTEMPTS )

        # Once the buffer fills up send its contents to the master.
        @issue_buffer.on_flush { |buffer| send_issues_to_master( buffer ) }

        # Don't store issues locally.
        @modules.do_not_store
        @modules.on_register_results do |issues|
            # Only send summaries of issues to the master right away so that
            # the the master will have live data to show the user...
            send_issue_summaries_to_master issues

            # ...but buffer the complete issues to be sent in batches for better
            # bandwidth utilization.
            @issue_buffer.batch_push issues
        end

        true
    end

    private

    #
    # @note Should previously unseen elements dynamically appear during the
    #   audit they will override audit restrictions and each instance will audit
    #   them at will.
    #
    # If we're the master we'll need to analyze the pages prior to assigning
    # them to each instance at the element level so as to gain more granular
    # control over the assigned workload.
    #
    # Put simply, we'll need to perform some magic in order to prevent different
    # instances from auditing the same elements and wasting bandwidth.
    #
    # For example: Search forms, logout links and the like will most likely
    # exist on most pages of the site and since each instance is assigned a set
    # of URLs/pages to audit they will end up with common elements so we have to
    # prevent instances from performing identical checks.
    #
    def master_run
        # We need to take our cues from the local framework as some plug-ins may
        # need the system to wait for them to finish before moving on.
        sleep( 0.2 ) while paused?

        # Prepare a block to process each Dispatcher and request slave instances
        # from it.
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
                # We need to restrict the scope of our audit to the pages our
                # crawler discovered.
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
                    # Split the page array into chunks that will be distributed
                    # across the instances.
                    page_chunks = page_a.chunk( chunk_cnt )

                    # Assign us our fair share of plug-in discovered pages.
                    update_page_queue( page_chunks.pop, @local_token )

                    # Remove duplicate elements across the (per instance) chunks
                    # while spreading them out evenly.
                    elements = distribute_elements( chunks,
                                                    element_ids_per_page )

                    # Restrict the local instance to its assigned elements.
                    restrict_to_elements( elements.pop, @local_token )

                    # Set the URLs to be audited by the local instance.
                    @opts.restrict_paths = chunks.pop

                    chunks.each_with_index do |chunk, i|
                        # Distribute the audit workload tell the slaves to have
                        # at it.
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

                    # Don't ring our own bell unless there are no other
                    # instances set to scan.
                    cleanup_if_all_done if chunk_cnt == 1 || @running_slaves.any?
                }
            end

            # Let crawlers know of each other and start the scan.
            spider.update_peers( @instances ){ Thread.new { spider.run } }
        end

        # Get the Dispatchers with unique Pipe IDs in order to take advantage of
        # line aggregation.
        preferred_dispatchers do |pref_dispatchers|
            iterator_for( pref_dispatchers ).each( each, after )
        end
    end

    # If we're a slave we need to flush out issue buffer after the audit.
    def slave_run
        audit

        # Make sure we've reported all issues back to the master before telling
        # him that we're done.
        flush_issue_buffer do
            @master.framework.slave_done( self_url, master_priv_token ) do
                @extended_running = false
                @status = :done
            end
        end
    end

    # Cleans up the system if all Instances have finished.
    def cleanup_if_all_done
        return if !@finished_auditing || @running_slaves != @done_slaves

        # we pass a block because we want to perform a grid cleanup,
        # not just a local one
        clean_up do
            @extended_running = false
            @status = :done
        end
    end

    # @return   [Boolean]
    #   `true` if `token` matches the local privilege token, `false` otherwise.
    def valid_token?( token )
        @local_token == token
    end

    #
    # @note Won't report the issues immediately but instead buffer them and
    #   transmit them at the appropriate time.
    #
    # Reports an array of issues back to the master Instance.
    #
    # @param    [Array<Arachni::Issue>]     issues
    #
    # @see #report_issues_to_master
    #
    def report_issues_to_master( issues )
        @issue_buffer.batch_push issues
        true
    end

    #
    # Immediately flushes the issue buffer, sending those issues to the master
    # Instance.
    #
    # @param    [Block] block
    #   Block to call once the issues have been registered with the master.
    #
    # @see #report_issues_to_master
    #
    def flush_issue_buffer( &block )
        send_issues_to_master( @issue_buffer.flush, &block )
    end

    #
    # @param    [Array<Arachni::Issue>] issues
    # @param    [Block] block
    #   Block to call once the issues have been registered with the master.
    #
    def send_issues_to_master( issues, &block )
        @master.framework.register_issues( issues, master_priv_token, &block )
    end

    #
    # Sends a summary of issues to the master. Helps provide real-time time data
    # to the master (and subsequently, the user) but without maxing out our
    # bandwidth.
    #
    # Full issues will be transmitted according to the issue buffer policy.
    #
    # @param    [Array<Arachni::Issue>] issues
    # @param    [Block] block
    #   Block to call once the issues have been registered with the master.
    #
    def send_issue_summaries_to_master( issues, &block )
        @unique_issue_summaries ||= Set.new

        # Multiple variations for grep modules are not being filtered when
        # an issue is registered, and for good reason; however, we do need to
        # filter them in this case since we're summarizing.
        summaries = AuditStore.new( issues: issues ).issues.map do |i|
            next if @unique_issue_summaries.include?( i.unique_id )
            di = i.deep_clone
            di.variations.first || di
        end.compact

        @unique_issue_summaries |= summaries.each { |issue| issue.unique_id }
        @master.framework.register_issue_summaries( summaries, master_priv_token, &block )
    end

    # @return   [String]
    #   Privilege token for the master, we need this in order to call
    #   inter-Instance methods for reporting back to it.
    def master_priv_token
        @opts.datastore['master_priv_token']
    end

end
end
end
