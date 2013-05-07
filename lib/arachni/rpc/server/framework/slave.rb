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
# Holds methods for slave Instances, both for remote management and utility ones.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Slave

    # Buffer issues and only report them to the master instance when the buffer
    # reaches (or exceeds) this size.
    ISSUE_BUFFER_SIZE = 100

    # How many times to try and fill the issue buffer before flushing it.
    ISSUE_BUFFER_FILLUP_ATTEMPTS = 10

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
        # If we're already a member of a multi-Instance operation bail out.
        return false if !solo?

        # Make sure the desired plugins are loaded before #prepare runs them.
        plugins.load @opts.plugins if @opts.plugins

        # Start the clock and run the plugins.
        prepare

        @master = connect_to_instance( 'url' => url, 'token' => token )

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

        # Holds the sitemap of the local crawl.
        @local_sitemap   = Set.new

        # Process each page as it is crawled.
        # (The crawl will start the first time any Instance pushes paths to us.)
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

        # Setup a hook to be called every time we run out of paths.
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
                # Let the master know if we're done crawling.
                spider.signal_if_done @master
            end
        end

        # Buffer for logged issues that are to be sent to the master.
        @issue_buffer = Buffer::AutoFlush.new( ISSUE_BUFFER_SIZE,
                                               ISSUE_BUFFER_FILLUP_ATTEMPTS )

        # Once the buffer fills up and is about to flush itself, send its
        # contents to the master.
        @issue_buffer.on_flush { |buffer| send_issues_to_master( buffer ) }

        # Don't store issues locally -- will still filter duplicate issues though.
        @modules.do_not_store

        @modules.on_register_results do |issues|
            # Send summaries of issues to the master right away so that the the
            # master will have live data to show the user...
            send_issue_summaries_to_master issues

            # ...but buffer the complete issues to be sent in batches for better
            # bandwidth utilization.
            @issue_buffer.batch_push issues
        end

        true
    end

    # @return   [Bool]  `true` if this instance is a slave, `false` otherwise.
    def slave?
        # If we don't have a connection to the master then we're not a slave.
        !!@master
    end

    private

    #
    # Runs {Framework#audit} and takes care of slave duties like the
    # need to flush out the issue buffer after the audit and let the master
    # know when we're done.
    #
    def slave_run
        audit

        # Make sure we've reported all issues back to the master before telling
        # it that we're done.
        flush_issue_buffer do
            @master.framework.slave_done( self_url, master_priv_token ) do
                @extended_running = false
                @status = :done
            end
        end
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
    #   Privilege token for the master, we need this in order to report back to it.
    def master_priv_token
        @opts.datastore['master_priv_token']
    end

end

end
end
