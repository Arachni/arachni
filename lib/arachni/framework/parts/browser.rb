=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Framework
module Parts

# Provides access to the {BrowserCluster} and relevant helpers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Browser

    # @return   [BrowserCluster, nil]
    #   A lazy-loaded browser cluster or `nil` if
    #   {OptionGroups::BrowserCluster#pool_size} or
    #   {OptionGroups::Scope#dom_depth_limit} are 0 or not
    #   {#host_has_browser?}.
    def browser_cluster
        return if !use_browsers?

        # Initialization may take a while so since we lazy load this make sure
        # that only one thread gets to this code at a time.
        synchronize do
            if !@browser_cluster
                state.set_status_message :browser_cluster_startup
            end

            @browser_cluster ||= BrowserCluster.new
            state.clear_status_messages

            @browser_cluster.on_queue do
                if pause?
                    print_debug 'Blocking browser cluster on queue.'
                end

                wait_if_paused
            end

            @browser_cluster.on_job_done do
                if pause?
                    print_debug 'Blocking browser cluster on job done.'
                end

                wait_if_paused
            end

            @browser_cluster
        end
    end

    def browser
        return if !use_browsers?

        @browser ||= Arachni::Browser.new( store_pages: false )
    end

    # @return   [Bool]
    #   `true` if the environment has a browser, `false` otherwise.
    def host_has_browser?
        Arachni::Browser.has_executable?
    end

    def wait_for_browser_cluster?
        @browser_cluster && !browser_cluster.done?
    end

    # @private
    def browser_cluster_job_skip_states
        return if !@browser_cluster
        browser_cluster.skip_states( browser_job.id )
    end

    # @private
    def apply_dom_metadata( page )
        return false if page.dom.depth > 0 || !page.has_script? ||
            !browser

        # This optimization only affects Form::DOM elements, so don't bother
        # if none of the checks are interested in any of them.
        return false if !checks.values.find do |c|
            c.check? page, [Element::Form::DOM, Element::Cookie::DOM]
        end

        begin
            bp = browser.load( page ).to_page
        rescue Selenium::WebDriver::Error::WebDriverError,
            Watir::Exception::Error => e
            print_debug "Could not apply metadata to '#{page.dom.url}'" <<
                                    " because: #{e} [#{e.class}"
            return
        end

        # Request timeout or some other failure...
        return if bp.code == 0

        page.import_metadata( bp, :skip_dom )

        true
    ensure
        browser.clear_buffers if browser
    end

    def use_browsers?
        options.browser_cluster.pool_size > 0 &&
            options.scope.dom_depth_limit > 0 && host_has_browser?
    end

    private

    def shutdown_browser
        return if !@browser

        @browser.shutdown
        @browser = nil
    end

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
