=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class Framework
module Parts

# Provides {Page} audit functionality and everything related to it, like
# handling the {Session} and {Trainer}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Audit
    include Support::Mixins::Observable

    # @!method on_page_audit( &block )
    advertise :on_page_audit

    # @!method on_effective_page_audit( &block )
    advertise :on_effective_page_audit

    # @!method after_page_audit( &block )
    advertise :after_page_audit

    # @return   [Trainer]
    attr_reader :trainer

    # @return   [Session]
    #   Web application session manager.
    attr_reader :session

    # @return   [Arachni::HTTP]
    attr_reader :http

    # @return   [Array<String>]
    #   Page URLs which elicited no response from the server and were not audited.
    #   Not determined by HTTP status codes, we're talking network failures here.
    attr_reader :failures

    def initialize
        super

        @http = HTTP::Client.instance

        # Holds page URLs which returned no response.
        @failures = []
        @retries  = {}

        @current_url = ''

        reset_session
        reset_trainer
    end

    # @note Will update the {HTTP::Client#cookie_jar} with {Page#cookie_jar}.
    # @note It will audit just the given `page` and not any subsequent pages
    #   discovered by the {Trainer} -- i.e. ignore any new elements that might
    #   appear as a result.
    # @note It will pass the `page` to the {BrowserCluster} for analysis if the
    #   {Page::Scope#dom_depth_limit_reached? DOM depth limit} has
    #   not been reached and push resulting pages to {#push_to_page_queue} but
    #   will not audit those pages either.
    #
    # @param    [Page]    page
    #   Runs loaded checks against `page`
    def audit_page( page )
        return if !page

        if page.scope.out?
            print_info "Ignoring page due to exclusion criteria: #{page.dom.url}"
            return false
        end

        # Initialize the BrowserCluster.
        browser_cluster

        state.audited_page_count += 1
        add_to_sitemap( page )

        print_line

        if page.response.ok?
            print_status "[HTTP: #{page.code}] #{page.dom.url}"
        else
            print_error "[HTTP: #{page.code}] #{page.dom.url}"
            print_error "[#{page.response.return_code}] #{page.response.return_message}"
        end

        if page.platforms.any?
            print_info "Identified as: #{page.platforms.to_a.join( ', ' )}"
        end

        if crawl?
            pushed = push_paths_from_page( page )
            print_info "Analysis resulted in #{pushed.size} usable paths."
        end

        if host_has_browser?
            print_info "DOM depth: #{page.dom.depth} (Limit: " <<
                           "#{options.scope.dom_depth_limit})"

            if page.dom.transitions.any?
                print_info '  Transitions:'
                page.dom.print_transitions( method(:print_info), '    ' )
            end
        end

        # Aside from plugins and whatnot, the Trainer hooks here to update the
        # ElementFilter so that it'll know if new elements appear during the
        # audit, so it's a big deal.
        notify_on_page_audit( page )

        @current_url = page.dom.url.to_s

        http.update_cookies( page.cookie_jar )

        # Pass the page to the BrowserCluster to explore its DOM and feed
        # resulting pages back to the framework.
        perform_browser_analysis( page )

        run_http = false

        if checks.any?
            # Remove elements which have already passed through here.
            pre_audit_element_filter( page )

            notify_on_effective_page_audit( page )

            # Run checks which **don't** benefit from fingerprinting first, so
            # that we can use the responses of their HTTP requests to fingerprint
            # the webapp platforms, so that the checks which **do** benefit from
            # knowing the remote platforms can run more efficiently.
            run_http = run_checks( @checks.without_platforms, page )
            run_http = true if run_checks( @checks.with_platforms, page )
        end

        notify_after_page_audit( page )

        # Makes it easier on the GC but it is important that it be called
        # **after** all the callbacks have been executed because they may need
        # access to the cached data and there's no sense in re-parsing.
        page.clear_cache

        if Arachni::Check::Auditor.has_timeout_candidates?
            print_line
            print_status "Processing timeout-analysis candidates for: #{page.dom.url}"
            print_info   '-------------------------------------------'
            Arachni::Check::Auditor.timeout_audit_run
            run_http = true
        end

        run_http
    end

    private

    # Performs the audit.
    def audit
        handle_signals
        return if aborted?

        state.status = :scanning if !pausing?

        push_to_url_queue( options.url )
        options.scope.extend_paths.each { |url| push_to_url_queue( url ) }
        options.scope.restrict_paths.each { |url| push_to_url_queue( url, true ) }

        # Initialize the BrowserCluster.
        browser_cluster

        # Keep auditing until there are no more resources in the queues and the
        # browsers have stopped spinning.
        loop do
            show_workload_msg = true
            while !has_audit_workload? && wait_for_browser_cluster?
                if show_workload_msg
                    print_line
                    print_status 'Workload exhausted, waiting for new pages' <<
                                     ' from the browser-cluster...'
                end
                show_workload_msg = false

                last_pending_jobs ||= 0
                pending_jobs = browser_cluster.pending_job_counter
                if pending_jobs != last_pending_jobs
                    browser_cluster.print_info "Pending jobs: #{pending_jobs}"

                    browser_cluster.print_debug 'Current jobs:'
                    browser_cluster.workers.each do |worker|
                        browser_cluster.print_debug worker.job.to_s
                    end
                end
                last_pending_jobs = pending_jobs

                sleep 0.1
            end

            audit_queues

            next sleep( 0.1 ) if wait_for_browser_cluster?
            break if page_limit_reached?
            break if !has_audit_workload?
        end
    end

    # Audits the {Data::Framework.url_queue URL} and {Data::Framework.page_queue Page}
    # queues while maintaining a valid session with the webapp if we've got
    # login capabilities.
    def audit_queues
        return if @audit_queues_done == false || !has_audit_workload? ||
            page_limit_reached?

        @audit_queues_done = false

        while !suspended? && !page_limit_reached? && (page = pop_page)

            session.ensure_logged_in

            replenish_page_queue_from_url_queue

            # We're counting on piggybacking the page queue replenishing on the
            # page audit, however if there wasn't an audit we need to force an
            # HTTP run.
            audit_page( page ) or http.run

            handle_signals
        end

        @audit_queues_done = true
    end

    def harvest_http_responses
        print_status 'Harvesting HTTP responses...'
        print_info 'Depending on server responsiveness and network' <<
                       ' conditions this may take a while.'

        http.run
    end

end

end
end
end
