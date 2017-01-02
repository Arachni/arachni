=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

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

            @browser_cluster ||= BrowserCluster.new(
                on_pop: proc do
                    next if !pause?

                    print_debug 'Blocking browser cluster on pop.'
                    wait_if_paused
                end
            )
            state.clear_status_messages

            @browser_cluster
        end
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

    def use_browsers?
        options.browser_cluster.pool_size > 0 &&
            options.scope.dom_depth_limit > 0 && host_has_browser?
    end

    private

    def shutdown_browser_cluster
        return if !@browser_cluster

        browser_cluster.shutdown

        @browser_cluster = nil
        @browser_job     = nil
    end

    def browser_job_update_skip_states( states )
        return if states.empty?
        browser_cluster.update_skip_states browser_job.id, states
    end

    def handle_browser_page( result, * )
        page = result.is_a?( Page ) ? result : result.page

        synchronize do
            return if !push_to_page_queue page

            print_status "Got new page from the browser-cluster: #{page.dom.url}"
            print_info "DOM depth: #{page.dom.depth} (Limit: #{options.scope.dom_depth_limit})"

            if page.dom.transitions.any?
                print_info '  Transitions:'
                page.dom.print_transitions( method(:print_info), '    ' )
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

        # We need to schedule a separate job for applying metadata because it
        # needs to have a clean state.
        schedule_dom_metadata_application( page )

        @perform_browser_analysis_cb ||= method(:handle_browser_page)
        browser_cluster.queue(
            browser_job.forward( resource: page.dom.state ),
            @perform_browser_analysis_cb
        )

        true
    end

    def schedule_dom_metadata_application( page )
        return if page.dom.depth > 0
        return if page.metadata.map { |_, data| data['skip_dom'].values }.
            flatten.compact.any?

        # This optimization only affects Form & Cookie DOM elements,
        # so don't bother if none of the checks are interested in them.
        return if !checks.values.
            find { |c| c.check? page, [Element::Form::DOM, Element::Cookie::DOM], true }

        dom = page.dom.state
        dom.page = nil # Help out the GC.

        @dom_metadata_application_cb ||= method(:apply_dom_metadata)
        browser_cluster.with_browser dom, @dom_metadata_application_cb
    end

    def apply_dom_metadata( browser, dom )
        bp = nil

        begin
            bp = browser.load( dom, take_snapshot: false ).to_page
        rescue Selenium::WebDriver::Error::WebDriverError,
            Watir::Exception::Error => e
            print_debug "Could not apply metadata to '#{dom.url}'" <<
                            " because: #{e} [#{e.class}"
            return
        end

        # Request timeout or some other failure...
        return if bp.code == 0

        handle_browser_page bp
    end

    def browser_job
        # We'll recycle the same job since all of them will have the same
        # callback. This will force the BrowserCluster to use the same block
        # for all queued jobs.
        #
        # Also, this job should never end so that all analysis operations
        # share the same state.
        @browser_job ||= BrowserCluster::Jobs::DOMExploration.new(
            never_ending: true
        )
    end

end

end
end
end
