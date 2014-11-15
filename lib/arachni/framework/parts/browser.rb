=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Framework
module Parts

module Browser

    # @return   [BrowserCluster, nil]
    #   A lazy-loaded browser cluster or `nil` if
    #   {OptionGroups::BrowserCluster#pool_size} or
    #   {OptionGroups::Scope#dom_depth_limit} are 0 or not
    #   {#host_has_browser?}.
    def browser_cluster
        return if options.browser_cluster.pool_size == 0 ||
            Options.scope.dom_depth_limit == 0 || !host_has_browser?

        # Initialization may take a while so since we lazy load this make sure
        # that only one thread gets to this code at a time.
        synchronize do
            if !@browser_cluster
                state.set_status_message :browser_cluster_startup
            end

            @browser_cluster ||= BrowserCluster.new
            state.clear_status_messages
            @browser_cluster
        end
    end

    # @return   [Bool]
    #   `true` if the environment has a browser, `false` otherwise.
    def host_has_browser?
        Arachni::Browser.has_executable?
    end

    def wait_for_browser?
        @browser_cluster && !browser_cluster.done?
    end

    def browser_job_skip_states
        return if !@browser_cluster
        browser_cluster.skip_states( browser_job.id )
    end

    private

    def shutdown_browser_cluster
        return if !@browser_cluster

        browser_cluster.shutdown

        @browser_cluster = nil
        @browser_job     = nil
    end

    def browser_sitemap
        return {} if !@browser_cluster
        browser_cluster.sitemap
    end

    def browser_job_update_skip_states( states )
        return if states.empty?
        browser_cluster.update_skip_states browser_job.id, states
    end

    def handle_browser_page( page )
        synchronize do
            return if !push_to_page_queue page

            pushed_paths = nil
            if crawl?
                pushed_paths = push_paths_from_page( page ).size
            end

            print_status "Got new page from the browser-cluster: #{page.dom.url}"
            print_info "DOM depth: #{page.dom.depth} (Limit: #{options.scope.dom_depth_limit})"

            if page.dom.transitions.any?
                print_info '  Transitions:'
                page.dom.print_transitions( method(:print_info), '    ' )
            end

            if pushed_paths
                print_info "  -- Analysis resulted in #{pushed_paths} usable paths."
            end
        end
    end

    # Passes the `page` to {BrowserCluster#queue} and then pushes
    # the resulting pages to {#push_to_page_queue}.
    #
    # @param    [Page]  page
    #   Page to analyze.
    def perform_browser_analysis( page )
        return if !browser_cluster || !accepts_more_pages? ||
            Options.scope.dom_depth_limit.to_i < page.dom.depth + 1 ||
            !page.has_script?

        browser_cluster.queue( browser_job.forward( resource: page ) ) do |response|
            handle_browser_page response.page
        end

        true
    end

    def browser_job
        # We'll recycle the same job since all of them will have the same
        # callback. This will force the BrowserCluster to use the same block
        # for all queued jobs.
        #
        # Also, this job should never end so that all analysis operations
        # share the same state.
        @browser_job ||= BrowserCluster::Jobs::ResourceExploration.new(
            never_ending: true
        )
    end

end

end
end
end
