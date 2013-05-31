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
# Holds methods for master Instances, both for remote management and utility ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Master

    #
    # Sets this instance as the master.
    #
    # @return   [Bool]
    #   `true` on success, `false` if this instance is not a {#solo? solo} one.
    #
    def set_as_master
        return false if !solo?

        # Holds info for our slave Instances -- if we have any.
        @instances        = []

        # Instances which have been distributed some scan workload.
        @running_slaves   = Set.new

        # Instances which have completed their scan.
        @done_slaves      = Set.new

        # Holds element IDs for each page, to be used as a representation of the
        # the audit workload that will need to be distributed.
        @element_ids_per_url = {}

        # Some methods need to be accessible over RPC for instance management,
        # restricting elements, adding more pages etc.
        #
        # However, when in multi-Instance mode, the master should not be tampered
        # with, so we generate a local token (which is not known to regular API clients)
        # to be used server side by self to facilitate access control and only
        # allow slaves to update our runtime data.
        @local_token = Utilities.generate_token

        true
    end

    # @return   [Bool]
    #   `true` if running in HPG (High Performance Grid) mode and instance is
    #   the master, false otherwise.
    def master?
        # Only master needs a local token.
        !!@local_token
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

        # Take charge of the Instance we were given.
        instance = connect_to_instance( instance_info )
        instance.opts.set( cleaned_up_opts ) do
            instance.framework.set_master( multi_self_url, token ) do
                @instances << instance_info
                block.call true if block_given?
            end
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
    def update_issues( issues, token = nil )
        return false if master? && !valid_token?( token )
        @modules.class.register_results( issues )
        true
    end

    #
    # Used by slave crawlers to update the master's list of element IDs per URL.
    #
    # @param    [Hash]     element_ids_per_url
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
    def update_element_ids_per_url( element_ids_per_url = {}, token = nil )
        return false if master? && !valid_token?( token )

        element_ids_per_url.each do |url, ids|
            @element_ids_per_url[url] ||= []
            @element_ids_per_url[url] |= ids
        end

        true
    end

    #
    # Used by slaves to impart the knowledge they've gained during the scan to
    # the master as well as for signaling.
    #
    # @param    [Hash]     data
    # @option data [Boolean] :crawl_done
    #   `true` if the peer has finished crawling, `false` otherwise.
    # @option data [Boolean] :audit_done
    #   `true` if the slave has finished auditing, `false` otherwise.
    # @option data [Hash] :element_ids_per_url
    #   List of element IDs (as created by
    #   {Arachni::Element::Capabilities::Auditable#scope_audit_id}) for each
    #   page (by URL).
    # @option data [Hash] :platforms
    #   List of platforms (as created by {Platform::Manager.light}).
    # @option data [Array<Arachni::Issue>]    issues
    #
    # @param    [String]    url
    #   URL of the slave.
    # @param    [String]    token
    #   Privileged token, prevents this method from being called by 3rd parties
    #   when this instance is a master. If this instance is not a master one
    #   the token needn't be provided.
    #
    # @return   [Bool]  `true` on success, `false` on invalid `token`.
    #
    # @private
    #
    def slave_sitrep( data, url, token = nil )
        return false if master? && !valid_token?( token )

        update_element_ids_per_url( data[:element_ids_per_url] || {}, token )
        update_issues( data[:issues] || [], token )

        Platform::Manager.update_light( data[:platforms] || {} ) if Options.fingerprint?

        spider.peer_done( url ) if data[:crawl_done]
        slave_done( url, token ) if data[:audit_done]

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
        # from it. If we have any available Dispatchers that is...
        each = proc do |d_url, iterator|
            if ignore_grid?
                iterator.next
                next
            end

            d_opts = {
                'rank'   => 'slave',
                'target' => @opts.url,
                'master' => multi_self_url
            }

            connect_to_dispatcher( d_url ).dispatch( multi_self_url, d_opts ) do |instance_hash|
                enslave( instance_hash ){ |b| iterator.next }
            end
        end

        # Prepare a block to process the slave instances and start the scan.
        after = proc do
            @status = :crawling

            spider.on_each_page do |page|
                # Update the list of element scope-IDs per page -- will be used
                # as a whitelist for the distributed audit.
                update_element_ids_per_url(
                    { page.url => build_elem_list( page ) },
                    @local_token
                )
            end

            spider.on_complete do
                # Guess what we're doing now...
                @status = :distributing

                # The plugins may have updated the page queue so we need to take
                # these pages into account as well.
                page_a = []
                while !@page_queue.empty? && page = @page_queue.pop
                    page_a << page
                    update_element_ids_per_url(
                        { page.url => build_elem_list( page ) },
                        @local_token
                    )
                end

                # Split the URLs of the pages in equal chunks.
                chunks    = split_urls( @element_ids_per_url.keys, @instances.size + 1 )
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
                                                    @element_ids_per_url )

                    # Restrict the local instance to its assigned elements.
                    restrict_to_elements( elements.shift, @local_token )

                    # Set the URLs to be audited by the local instance.
                    @opts.restrict_paths = chunks.shift

                    chunks.each_with_index do |chunk, i|
                        # Distribute the audit workload and tell the slaves to
                        # have at it.
                        distribute_and_run( @instances[i],
                                            urls:     chunk,
                                            elements: elements.shift,
                                            pages:    page_chunks.shift )
                    end
                end

                # Start the master/local Instance's audit.
                Thread.abort_on_exception = true
                Thread.new {
                    audit

                    @finished_auditing = true

                    # Don't ring our own bell unless there are no other instances
                    # set to scan or we have slaves running.
                    #
                    # If the local audit finishes super-fast the slaves might
                    # not have been added to the local list yet, which will result
                    # in us prematurely cleaning up and setting the status to
                    # 'done' even though the slaves won't have yet finished
                    #
                    # However, if the workload chunk is 1 then no slaves will
                    # have been started in the first place since it's just us
                    # we can go ahead and clean-up.
                    cleanup_if_all_done if chunk_cnt == 1 || @running_slaves.any?
                }
            end

            # Let crawlers know of each other and start the master crawler.
            # The master will then push paths to its slaves thus waking them up
            # to join the crawl.
            spider.update_peers( @instances ) do
                Thread.abort_on_exception = true
                Thread.new { spider.run }
            end
        end

        # Get the Dispatchers with unique Pipe IDs in order to take advantage of
        # line aggregation.
        preferred_dispatchers do |pref_dispatchers|
            iterator_for( pref_dispatchers ).each( each, after )
        end
    end

    # Cleans up the system if all Instances have finished.
    def cleanup_if_all_done
        return if !@finished_auditing || @running_slaves != @done_slaves

        # We pass a block because we want to perform a grid cleanup, not just a
        # local one.
        clean_up{}
    end

    def has_slaves?
        @instances && @instances.any?
    end

    def auditstore_sitemap
        spider.sitemap
    end

end

end
end
