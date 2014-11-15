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

Dir.glob( "#{lib}framework/parts/**/*.rb" ).each { |h| require h }

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

    include Parts::Data
    include Parts::State
    include Parts::Scope
    include Parts::Browser
    include Parts::Report
    include Parts::Plugin
    include Parts::Check
    include Parts::Platform
    include Parts::Audit

    # @!method on_page_audit( &block )
    advertise :on_page_audit

    # @!method after_page_audit( &block )
    advertise :after_page_audit

    # {Framework} error namespace.
    #
    # All {Framework} errors inherit from and live under it.
    #
    # When I say Framework I mean the {Framework} class, not the entire Arachni
    # Framework.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Arachni::Error
    end

    # How many times to request a page upon failure.
    AUDIT_PAGE_MAX_TRIES = 5

    # @return   [Options]
    #   System options
    attr_reader :options

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

    # @param    [Options]    options
    # @param    [Block]      block
    #   Block to be passed a {Framework} instance which will then be {#reset}.
    def initialize( options = Arachni::Options.instance, &block )
        Encoding.default_external = 'BINARY'
        Encoding.default_internal = 'BINARY'

        @options = options

        super()

        reset_session
        @http = HTTP::Client.instance

        reset_trainer

        # Deep clone the redundancy rules to preserve their original counters
        # for the reports.
        @orig_redundant = options.scope.redundant_path_patterns.deep_clone

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

    # @return    [String]
    #   Returns the version of the framework.
    def version
        Arachni::VERSION
    end

    private

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

    def harvest_http_responses
        print_status 'Harvesting HTTP responses...'
        print_info 'Depending on server responsiveness and network' <<
            ' conditions this may take a while.'

        # Run all the queued HTTP requests and harvest the responses.
        http.run

        # Needed for some HTTP callbacks.
        http.run
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
