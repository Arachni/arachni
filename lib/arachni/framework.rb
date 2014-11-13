# encoding: utf-8

=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'rubygems'
require 'monitor'
require 'bundler/setup'

require 'ap'
require 'pp'

require_relative 'options'

module Arachni

lib = Options.paths.lib
require lib + 'version'
require lib + 'ruby'
require lib + 'error'
require lib + 'scope'
require lib + 'utilities'
require lib + 'support'
require lib + 'uri'
require lib + 'component'
require lib + 'platform'
require lib + 'http'
require lib + 'snapshot'
require lib + 'parser'
require lib + 'issue'
require lib + 'check'
require lib + 'plugin'
require lib + 'report'
require lib + 'reporter'
require lib + 'session'
require lib + 'trainer'
require lib + 'browser_cluster'

# The Framework class ties together all the systems.
#
# It's the brains of the operation, it bosses the rest of the subsystems around.
# It runs the audit, loads checks and reports and runs them according to
# user options.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Framework
    include UI::Output

    include Utilities
    include Support::Mixins::Observable

    # @!method on_page_audit( &block )
    advertise :on_page_audit

    # @!method after_page_audit( &block )
    advertise :after_page_audit

    # {Framework} error namespace.
    #
    # All {Framework} errors inherit from and live under it.
    #
    # When I say Framework I mean the {Framework} class, not the
    # entire Arachni Framework.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Arachni::Error
    end

    # How many times to request a page upon failure.
    AUDIT_PAGE_MAX_TRIES = 5

    # @return   [Options]
    #   System options
    attr_reader :options

    # @return   [Arachni::Reporter::Manager]
    attr_reader :reporters

    # @return   [Arachni::Check::Manager]
    attr_reader :checks

    # @return   [Arachni::Plugin::Manager]
    attr_reader :plugins

    # @return   [Session]
    #   Web application session manager.
    attr_reader :session

    # @return   [Arachni::HTTP]
    attr_reader :http

    # @return   [Trainer]
    attr_reader :trainer

    # @return [Array<String>]
    #   Page URLs which elicited no response from the server and were not audited.
    #   Not determined by HTTP status codes, we're talking network failures here.
    attr_reader :failures

    # @param   [String]    afs
    #   Path to an `.afs.` (Arachni Framework Snapshot) file created by {#suspend}.
    #
    # @return   [Framework]
    #   Restored instance.
    def self.restore( afs, &block )
        framework = new
        framework.restore( afs )

        if block_given?
            begin
                block.call framework
            ensure
                framework.clean_up
                framework.reset
            end
        end

        framework
    end

    # @param    [Options]    options
    # @param    [Block]      block
    #   Block to be passed a {Framework} instance which will then be {#reset}.
    def initialize( options = Arachni::Options.instance, &block )
        super()

        Encoding.default_external = 'BINARY'
        Encoding.default_internal = 'BINARY'

        @options = options

        @checks    = Check::Manager.new( self )
        @reporters = Reporter::Manager.new
        @plugins   = Plugin::Manager.new( self )

        reset_session
        @http = HTTP::Client.instance

        reset_trainer

        # Deep clone the redundancy rules to preserve their original counters
        # for the reports.
        @orig_redundant = options.scope.redundant_path_patterns.deep_clone

        state.status = :ready

        @current_url = ''

        # Holds page URLs which returned no response.
        @failures = []
        @retries  = {}

        @after_page_audit_blocks = []

        # Little helper to run a piece of code and reset the framework to be
        # ready to be reused.
        if block_given?
            begin
                block.call self
            ensure
                clean_up
                reset
            end
        end
    end

    # @return   [Integer]
    #   Total number of pages added to the {#push_to_page_queue page audit queue}.
    def page_queue_total_size
        data.page_queue_total_size
    end

    # @return   [Integer]
    #   Total number of URLs added to the {#push_to_url_queue URL audit queue}.
    def url_queue_total_size
        data.url_queue_total_size
    end

    # @return   [Hash<String, Integer>]
    #   List of crawled URLs with their HTTP codes.
    def sitemap
        data.sitemap
    end

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

    # Starts the scan.
    #
    # @param   [Block]  block
    #   A block to call after the audit has finished but before running {#reporters}.
    def run( &block )
        prepare
        handle_signals
        return if aborted?

        # Catch exceptions so that if something breaks down or the user opted to
        # exit the reporters will still run with whatever results Arachni managed
        # to gather.
        exception_jail( false ){ audit }
        # print_with_statistics

        return if aborted?
        return if suspended?

        clean_up
        exception_jail( false ){ block.call } if block_given?
        state.status = :done

        true
    end

    # @return   [State::Framework]
    def state
        State.framework
    end

    # @return   [Data::Framework]
    def data
        Data.framework
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
        sitemap.merge!( browser_sitemap )

        print_line
        print_status "[HTTP: #{page.code}] #{page.dom.url}"

        if page.platforms.any?
            print_info "Identified as: #{page.platforms.to_a.join( ', ' )}"
        end

        if crawl?
            pushed = push_paths_from_page( page )
            print_info "Analysis resulted in #{pushed.size} usable paths."
        end

        if host_has_browser?
            print_info "DOM depth: #{page.dom.depth} (Limit: #{options.scope.dom_depth_limit})"

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
        perform_browser_analysis( page )

        # Remove elements which have already passed through here.
        pre_audit_element_filter( page )

        # Run checks which **don't** benefit from fingerprinting first, so that
        # we can use the responses of their HTTP requests to fingerprint the
        # webapp platforms, so that the checks which **do** benefit from knowing
        # the remote platforms can run more efficiently.
        ran = false
        @checks.without_platforms.values.each do |check|
            ran = true if check_page( check, page )
        end
        harvest_http_responses if ran
        run_http = ran

        ran = false
        @checks.with_platforms.values.each do |check|
            ran = true if check_page( check, page )
        end
        harvest_http_responses if ran
        run_http ||= ran

        if Check::Auditor.has_timeout_candidates?
            print_line
            print_status "Verifying timeout-analysis candidates for: #{page.dom.url}"
            print_info '---------------------------------------'
            Check::Auditor.timeout_audit_run
            run_http = true
        end

        # Makes it easier on the GC.
        page.clear_cache

        notify_after_page_audit( page )
        run_http
    end

    # @return   [Bool]
    #   `true` if the environment has a browser, `false` otherwise.
    def host_has_browser?
        Browser.has_executable?
    end

    # @return   [Bool]
    #   `true` if the {OptionGroups::Scope#page_limit} has been reached,
    #   `false` otherwise.
    def page_limit_reached?
        options.scope.page_limit_reached?( sitemap.size )
    end

    def crawl?
        options.scope.crawl? && options.scope.restrict_paths.empty?
    end

    # @return   [Bool]
    #   `true` if the framework can process more pages, `false` is scope limits
    #   have been reached.
    def accepts_more_pages?
        crawl? && !page_limit_reached?
    end

    # @return   [Hash]
    #
    #   Framework statistics:
    #
    #   *  `:http`          -- {HTTP::Client#statistics}
    #   *  `:runtime`       -- Scan runtime in seconds.
    #   *  `:found_pages`   -- Number of discovered pages.
    #   *  `:audited_pages` -- Number of audited pages.
    #   *  `:current_page`  -- URL of the currently audited page.
    #   *  `:status`        -- {#status}
    #   *  `:messages`      -- {#status_messages}
    def statistics
        {
            http:          http.statistics,
            runtime:       @start_datetime ? Time.now - @start_datetime : 0,
            found_pages:   sitemap.size,
            audited_pages: state.audited_page_count,
            current_page:  @current_url
        }
    end

    # @return   [Array<String>]
    #   Messages providing more information about the current {#status} of
    #   the framework.
    def status_messages
        state.status_messages
    end

    # @param    [Page]  page
    #   Page to push to the page audit queue -- increases {#page_queue_total_size}
    #
    # @return   [Bool]
    #   `true` if push was successful, `false` if the `page` matched any
    #   exclusion criteria or has already been seen.
    def push_to_page_queue( page, force = false )
        return false if !force && (!accepts_more_pages? || state.page_seen?( page ) ||
            page.scope.out? || page.scope.redundant?)

        # We want to update from the already loaded page cache (if there is one)
        # as we have to store the page anyways (needs to go through Browser analysis)
        # and it's not worth the resources to parse its elements.
        #
        # We're basically doing this to give the Browser and Trainer a better
        # view of what elements have been seen, so that they won't feed us pages
        # with elements that they think are new, but have been provided to us by
        # some other component; however, it wouldn't be the end of the world if
        # that were to happen.
        ElementFilter.update_from_page_cache page

        data.push_to_page_queue page
        state.page_seen page

        true
    end

    # @param    [String]  url
    #   URL to push to the audit queue -- increases {#url_queue_total_size}
    #
    # @return   [Bool]
    #   `true` if push was successful, `false` if the `url` matched any
    #   exclusion criteria or has already been seen.
    def push_to_url_queue( url, force = false )
        return if !force && !accepts_more_pages?

        url = to_absolute( url ) || url
        if state.url_seen?( url ) || skip_path?( url ) || redundant_path?( url )
            return false
        end

        data.push_to_url_queue url
        state.url_seen url

        true
    end

    # @return    [Report]
    #   Scan results.
    def report
        opts = options.to_hash.deep_clone

        # restore the original redundancy rules and their counters
        opts[:scope][:redundant_path_patterns] = @orig_redundant

        Report.new(
            options:         options,
            sitemap:         sitemap,
            issues:          Data.issues.sort,
            plugins:         @plugins.results,
            start_datetime:  @start_datetime,
            finish_datetime: @finish_datetime
        )
    end

    # Runs a reporter component and returns the contents of the generated report.
    #
    # Only accepts reporters which support an `outfile` option.
    #
    # @param    [String]    name
    #   Name of the reporter component to run, as presented by {#list_reporters}'s
    #   `:shortname` key.
    # @param    [Report]    external_report
    #   Report to use -- defaults to the local one.
    #
    # @return   [String]
    #   Scan report.
    #
    # @raise    [Component::Error::NotFound]
    #   If the given reporter name doesn't correspond to a valid reporter component.
    #
    # @raise    [Component::Options::Error::Invalid]
    #   If the requested reporter doesn't format the scan results as a String.
    def report_as( name, external_report = report )
        if !@reporters.available.include?( name.to_s )
            fail Component::Error::NotFound, "Reporter '#{name}' could not be found."
        end

        loaded = @reporters.loaded
        begin
            @reporters.clear

            if !@reporters[name].has_outfile?
                fail Component::Options::Error::Invalid,
                     "Reporter '#{name}' cannot format the audit results as a String."
            end

            outfile = "#{Dir.tmpdir}/#{generate_token}"
            @reporters.run( name, external_report, outfile: outfile )

            IO.binread( outfile )
        ensure
            File.delete( outfile ) if outfile
            @reporters.clear
            @reporters.load loaded
        end
    end

    # @return    [Array<Hash>]
    #   Information about all available {Checks}.
    def list_checks( patterns = nil )
        loaded = @checks.loaded

        begin
            @checks.clear
            @checks.available.map do |name|
                path = @checks.name_to_path( name )
                next if !list_check?( path, patterns )

                @checks[name].info.merge(
                    shortname: name,
                    author:    [@checks[name].info[:author]].
                                   flatten.map { |a| a.strip },
                    path:      path.strip,
                    platforms: @checks[name].platforms,
                    elements:  @checks[name].elements
                )
            end.compact
        ensure
            @checks.clear
            @checks.load loaded
        end
    end

    # @return    [Array<Hash>]
    #   Information about all available {Reporters}.
    def list_reporters( patterns = nil )
        loaded = @reporters.loaded

        begin
            @reporters.clear
            @reporters.available.map do |report|
                path = @reporters.name_to_path( report )
                next if !list_reporter?( path, patterns )

                @reporters[report].info.merge(
                    options:   @reporters[report].info[:options] || [],
                    shortname: report,
                    path:      path,
                    author:    [@reporters[report].info[:author]].
                                   flatten.map { |a| a.strip }
                )
            end.compact
        ensure
            @reporters.clear
            @reporters.load loaded
        end
    end

    # @return    [Array<Hash>]
    #   Information about all available {Plugins}.
    def list_plugins( patterns = nil )
        loaded = @plugins.loaded

        begin
            @plugins.clear
            @plugins.available.map do |plugin|
                path = @plugins.name_to_path( plugin )
                next if !list_plugin?( path, patterns )

                @plugins[plugin].info.merge(
                    options:   @plugins[plugin].info[:options] || [],
                    shortname: plugin,
                    path:      path,
                    author:    [@plugins[plugin].info[:author]].
                                   flatten.map { |a| a.strip }
                )
            end.compact
        ensure
            @plugins.clear
            @plugins.load loaded
        end
    end

    # @return    [Array<Hash>]
    #   Information about all available platforms.
    def list_platforms
        platforms = Platform::Manager.new
        platforms.valid.inject({}) do |h, platform|
            type = Platform::Manager::TYPES[platforms.find_type( platform )]
            h[type] ||= {}
            h[type][platform] = platforms.fullname( platform )
            h
        end
    end

    # @return   [Symbol]
    #   Status of the instance, possible values are (in order):
    #
    #   * `:ready` -- {#initialize Initialised} and waiting for instructions.
    #   * `:preparing` -- Getting ready to start (i.e. initializing plugins etc.).
    #   * `:scanning` -- The instance is currently {#run auditing} the webapp.
    #   * `:pausing` -- The instance is being {#pause paused} (if applicable).
    #   * `:paused` -- The instance has been {#pause paused} (if applicable).
    #   * `:suspending` -- The instance is being {#suspend suspended} (if applicable).
    #   * `:suspended` -- The instance has being {#suspend suspended} (if applicable).
    #   * `:cleanup` -- The scan has completed and the instance is
    #       {Framework#clean_up cleaning up} after itself (i.e. waiting for
    #       plugins to finish etc.).
    #   * `:aborted` -- The scan has been {Framework#abort}, you can grab the
    #       report and shutdown.
    #   * `:done` -- The scan has completed, you can grab the report and shutdown.
    def status
        state.status
    end

    # @return   [Bool]
    #   `true` if the framework is running, `false` otherwise. This is `true`
    #   even if the scan is {#paused?}.
    def running?
        state.running?
    end

    # @return   [Bool]
    #   `true` if the system is scanning, `false` otherwise.
    def scanning?
        state.scanning?
    end

    # @return   [Bool]
    #   `true` if the framework is paused, `false` otherwise.
    def paused?
        state.paused?
    end

    # @return   [Bool]
    #   `true` if the framework has been instructed to pause (i.e. is in the
    #   process of being paused or has been paused), `false` otherwise.
    def pause?
        state.pause?
    end

    # @return   [Bool]
    #   `true` if the framework is in the process of pausing, `false` otherwise.
    def pausing?
        state.pausing?
    end

    # @note Each call from a unique caller is counted as a pause request
    #   and in order for the system to resume **all** pause callers need to
    #   {#resume} it.
    #
    # Pauses the framework on a best effort basis.
    #
    # @param    [Bool]  wait
    #   Wait until the system has been paused.
    #
    # @return   [Integer]
    #   ID identifying this pause request.
    def pause( wait = true )
        id = generate_token.hash
        state.pause id, wait
        id
    end

    # @return   [Bool]
    #   `true` if the framework {#run} has been aborted, `false` otherwise.
    def aborted?
        state.aborted?
    end

    # @return   [Bool]
    #   `true` if the framework has been instructed to abort (i.e. is in the
    #   process of being aborted or has been aborted), `false` otherwise.
    def abort?
        state.abort?
    end

    # @return   [Bool]
    #   `true` if the framework is in the process of aborting, `false` otherwise.
    def aborting?
        state.aborting?
    end

    # Aborts the framework {#run} on a best effort basis.
    #
    # @param    [Bool]  wait
    #   Wait until the system has been aborted.
    def abort( wait = true )
        state.abort wait
    end

    # @note Each call from a unique caller is counted as a pause request
    #   and in order for the system to resume **all** pause callers need to
    #   {#resume} it.
    #
    # Removes a {#pause} request for the current caller.
    #
    # @param    [Integer]   id
    #   ID of the {#pause} request.
    def resume( id )
        state.resume id
    end

    # Writes a {Snapshot.dump} to disk and aborts the scan.
    #
    # @param   [Bool]  wait
    #   Wait for the system to write it state to disk.
    #
    # @return   [String,nil]
    #   Path to the state file `wait` is `true`, `nil` otherwise.
    def suspend( wait = true )
        state.suspend( wait )
        return snapshot_path if wait
        nil
    end

    # @return   [Bool]
    #   `true` if the system is in the process of being suspended, `false`
    #   otherwise.
    def suspend?
        state.suspend?
    end

    # @return   [Bool]
    #   `true` if the system has been suspended, `false` otherwise.
    def suspended?
        state.suspended?
    end

    # @return   [String]
    #   Provisioned {#suspend} dump file for this instance.
    def snapshot_path
        return @state_archive if @state_archive

        default_filename =
            "#{URI(options.url).host} #{Time.now.to_s.gsub( ':', '_' )} #{generate_token}.afs"

        location = options.snapshot.save_path

        if !location
            location = default_filename
        elsif File.directory? location
            location += "/#{default_filename}"
        end

        @state_archive ||= File.expand_path( location )
    end

    # @param   [String]    afs
    #   Path to an `.afs.` (Arachni Framework Snapshot) file created by {#suspend}.
    #
    # @return   [Framework]
    #   Restored instance.
    def restore( afs )
        Snapshot.load afs

        browser_job_update_skip_states state.browser_skip_states

        checks.load  Options.checks
        plugins.load Options.plugins.keys

        nil
    end

    def wait_for_browser?
        @browser_cluster && !browser_cluster.done?
    end

    # Cleans up the framework; should be called after running the audit or
    # after canceling a running scan.
    #
    # It stops the clock and waits for the plugins to finish up.
    def clean_up( shutdown_browsers = true )
        return if @cleaned_up
        @cleaned_up = true

        state.status = :cleanup

        sitemap.merge!( browser_sitemap )

        if shutdown_browsers
            state.set_status_message :browser_cluster_shutdown
            shutdown_browser_cluster
        end

        state.set_status_message :clearing_queues
        page_queue.clear
        url_queue.clear

        @finish_datetime  = Time.now
        @start_datetime ||= Time.now

        # Make sure this is disabled or it'll break reporter output.
        disable_only_positives

        state.running = false

        state.set_status_message :waiting_for_plugins
        @plugins.block

        # Plugins may need the session right till the very end so save it for last.
        @session.clean_up
        @session = nil

        true
    end

    def browser_job_skip_states
        return if !@browser_cluster
        browser_cluster.skip_states( browser_job.id )
    end

    # @return    [String]
    #   Returns the version of the framework.
    def version
        Arachni::VERSION
    end

    # @note Prefer this from {.reset} if you already have an instance.
    # @note You should first reset {Arachni::Options}.
    #
    # Resets everything and allows the framework to be re-used.
    def reset
        @cleaned_up  = false
        @browser_job = nil

        @failures.clear
        @retries.clear

        # This needs to happen before resetting the other components so they
        # will be able to put in their hooks.
        self.class.reset

        clear_observers
        reset_trainer
        reset_session
        @checks.clear
        @reporters.clear
        @plugins.clear
    end

    # @note You should first reset {Arachni::Options}.
    #
    # Resets everything and allows the framework environment to be re-used.
    def self.reset
        State.clear
        Data.clear

        Platform::Manager.reset
        Check::Auditor.reset
        ElementFilter.reset
        Element::Capabilities::Auditable.reset
        Element::Capabilities::Analyzable.reset
        Check::Manager.reset
        Plugin::Manager.reset
        Reporter::Manager.reset
        HTTP::Client.reset
    end

    # @private
    def reset_trainer
        @trainer = Trainer.new( self )
    end

    private

    def shutdown_browser_cluster
        return if !@browser_cluster

        browser_cluster.shutdown

        @browser_cluster = nil
        @browser_job     = nil
    end

    def push_paths_from_page( page )
        page.paths.select { |path| push_to_url_queue( path ) }
    end

    def browser_sitemap
        return {} if !@browser_cluster
        browser_cluster.sitemap
    end

    def browser_job_update_skip_states( states )
        return if states.empty?
        browser_cluster.update_skip_states browser_job.id, states
    end

    def reset_session
        @session.clean_up if @session
        @session = Session.new
    end

    def abort_if_signaled
        return if !abort?
        clean_up
        state.aborted
    end

    def suspend_if_signaled
        return if !suspend?
        suspend_to_disk
    end

    def suspend_to_disk
        while wait_for_browser?
            last_pending_jobs ||= 0
            pending_jobs = browser_cluster.pending_job_counter

            if pending_jobs != last_pending_jobs
                state.set_status_message :waiting_for_browser_cluster_jobs, pending_jobs
                print_info "Suspending: #{status_messages.first}"
            end

            last_pending_jobs = pending_jobs
            sleep 0.1
        end

        # Make sure the component options are up to date with what's actually
        # happening.
        options.checks  = checks.loaded
        options.plugins = plugins.loaded.
            inject({}) { |h, name| h[name.to_s] = Options.plugins[name.to_s] || {}; h }

        if browser_job_skip_states
            state.browser_skip_states.merge browser_job_skip_states
        end

        state.set_status_message :suspending_plugins
        @plugins.suspend

        state.set_status_message :saving_snapshot, snapshot_path
        Snapshot.dump( snapshot_path )
        state.clear_status_messages

        clean_up

        state.set_status_message :snapshot_location, snapshot_path
        print_info status_messages.first
        state.suspended
    end

    def handle_signals
        wait_if_paused
        abort_if_signaled
        suspend_if_signaled
    end

    def wait_if_paused
        state.paused if pause?
        sleep 0.2 while pause? && !abort?
    end

    # @note Must be called before calling any audit methods.
    #
    # Prepares the framework for the audit.
    #
    # * Sets the status to `:preparing`.
    # * Starts the clock.
    # * Runs the plugins.
    def prepare
        state.status  = :preparing
        state.running = true
        @start_datetime = Time.now

        Snapshot.restored? ? @plugins.restore : @plugins.run
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
            while !has_audit_workload? && wait_for_browser?
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
                end
                last_pending_jobs = pending_jobs

                sleep 0.1
            end

            audit_queues

            break if page_limit_reached?
            break if !has_audit_workload? && !wait_for_browser?
        end
    end

    def has_audit_workload?
        !url_queue.empty? || !page_queue.empty?
    end

    def page_queue
        data.page_queue
    end

    def url_queue
        data.url_queue
    end

    # Audits the {Data::Framework.url_queue URL} and {Data::Framework.page_queue Page}
    # queues while maintaining a valid session with the webapp if we've got
    # login capabilities.
    def audit_queues
        return if @audit_queues_done == false || !has_audit_workload? ||
            page_limit_reached?

        @audit_queues_done = false

        # If for some reason we've got pages in the page queue this early,
        # consume them and get it over with.
        audit_page_queue

        next_page = nil
        while !suspended? && !page_limit_reached? &&
            (page = next_page || pop_page_from_url_queue)

            # Helps us schedule the next page to be grabbed along with the audit
            # requests for the current page to avoid blocking.
            next_page = nil
            next_page_call = proc do
                pop_page_from_url_queue { |p| next_page = p }
            end

            # If we can login capabilities make sure that our session is valid
            # before grabbing and auditing the next page.
            if session.can_login?
                # Schedule the login check to happen along with the audit requests
                # to prevent blocking and grab the next page as well.
                session.logged_in? do |bool|
                    next next_page_call.call if bool

                    session.login
                    next_page_call
                end
            else
                next_page_call.call
            end

            # We're counting on piggybacking the next page retrieval with the
            # page audit, however if there wasn't an audit we need to force an
            # HTTP run.
            audit_page( page ) or http.run

            if next_page && suspend?
                data.page_queue << next_page
            end

            handle_signals

            # Consume pages somehow triggered by the audit and pushed by the
            # trainer or plugins or whatever.
            audit_page_queue
        end

        audit_page_queue

        @audit_queues_done = true
        true
    end

    def pop_page_from_url_queue( &block )
        return if url_queue.empty?

        grabbed_page = nil
        Page.from_url( url_queue.pop, http: { update_cookies: true } ) do |page|
            @retries[page.url.hash] ||= 0

            if (location = page.response.headers['Location'])
                print_info "Scheduled #{page.code} redirection: #{page.url} => #{location}"
                push_to_url_queue to_absolute( location, page.url )
            end

            if page.code != 0
                grabbed_page = page
                block.call grabbed_page if block_given?
                next
            end

            if @retries[page.url.hash] >= AUDIT_PAGE_MAX_TRIES
                @failures << page.url

                print_error "Giving up trying to audit: #{page.url}"
                print_error "Couldn't get a response after #{AUDIT_PAGE_MAX_TRIES} tries."
            else
                print_bad "Retrying for: #{page.url}"
                @retries[page.url.hash] += 1
                url_queue << page.url
            end

            grabbed_page = nil
            block.call grabbed_page if block_given?
        end
        http.run if !block_given?
        grabbed_page
    end

    # Audits the page queue.
    #
    # @see #pop_page_from_queue
    def audit_page_queue
        while !suspended? && !page_limit_reached? && (page = pop_page_from_queue)
            audit_page( page )
            handle_signals
        end
    end

    # @return   [Page]
    def pop_page_from_queue
        return if page_queue.empty?
        page_queue.pop
    end

    def harvest_http_responses
        print_status 'Harvesting HTTP responses...'
        print_info 'Depending on server responsiveness and network' <<
            ' conditions this may take a while.'

        # Run all the queued HTTP requests and harvest the responses.
        http.run

        # Needed for some HTTP callbacks.
        http.run
    end

    # Passes a page to the check and runs it.
    # It also handles any exceptions thrown by the check at runtime.
    #
    # @param    [Check::Base]   check
    #   Check to run.
    # @param    [Page]    page
    def check_page( check, page )
        begin
            @checks.run_one( check, page )
        rescue => e
            print_error "Error in #{check.to_s}: #{e.to_s}"
            print_error_backtrace e
            false
        end
    end

    # Small but (sometimes) important optimization:
    #
    # Keep track of page elements which have already been passed to checks,
    # in order to filter them out and hopefully even avoid running checks
    # against pages with no new elements.
    #
    # It's not like there were going to be redundant audits anyways, because
    # each layer of the audit performs its own redundancy checks, but those
    # redundancy checks can introduce significant latencies when dealing
    # with pages with lots of elements.
    def pre_audit_element_filter( page )
        redundant_elements  = {}
        page.elements.each do |e|
            next if !Options.audit.element?( e.type )
            next if e.is_a?( Cookie ) || e.is_a?( Header )

            new_element                  = false
            redundant_elements[e.type] ||= []

            if !state.element_checked?( e )
                state.element_checked e
                new_element = true
            end

            if e.respond_to?( :dom ) && e.dom
                if !state.element_checked?( e.dom )
                    state.element_checked e.dom
                    new_element = true
                end
            end

            next if new_element

            redundant_elements[e.type] << e
        end

        # Remove redundant elements from the page cache, if there are thousands
        # of them then just skipping them during the audit will introduce latency.
        redundant_elements.each do |type, elements|
            page.send( "#{type}s=", page.send( "#{type}s" ) - elements )
        end

        page
    end

    def add_to_sitemap( page )
        data.add_page_to_sitemap( page )
    end

    def list_reporter?( path, patterns = nil )
        regexp_array_match( patterns, path )
    end

    def list_check?( path, patterns = nil )
        regexp_array_match( patterns, path )
    end

    def list_plugin?( path, patterns = nil )
        regexp_array_match( patterns, path )
    end

    def regexp_array_match( regexps, str )
        regexps = [regexps].flatten.compact.
            map { |s| s.is_a?( Regexp ) ? s : Regexp.new( s.to_s ) }
        return true if regexps.empty?

        cnt = 0
        regexps.each { |filter| cnt += 1 if str =~ filter }
        cnt == regexps.size
    end

end
end
