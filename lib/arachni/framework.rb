# encoding: utf-8

=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'rubygems'
require 'monitor'
require 'bundler/setup'

require_relative 'options'

module Arachni

lib = Options.paths.lib
require lib + 'version'
require lib + 'support'
require lib + 'ruby'
require lib + 'error'
require lib + 'scope'
require lib + 'utilities'
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

# The Framework class ties together all the subsystems.
#
# It's the brains of the operation, it bosses the rest of the subsystems around.
# It loads checks, reports and plugins and runs them according to user options.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Framework
    include UI::Output
    include Utilities

    # How many times to request a page upon failure.
    AUDIT_PAGE_MAX_TRIES = 5

    include Parts::Scope
    include Parts::Browser
    include Parts::Report
    include Parts::Plugin
    include Parts::Check
    include Parts::Platform
    include Parts::Audit
    include Parts::Data
    include Parts::State

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

    # @return   [Options]
    #   System options
    attr_reader :options

    # @param    [Options]    options
    # @param    [Block]      block
    #   Block to be passed a {Framework} instance which will then be {#reset}.
    def initialize( options = Options.instance, &block )
        Encoding.default_external = 'BINARY'
        Encoding.default_internal = 'BINARY'

        @options = options

        # Initialize the Parts.
        super()

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

        return if aborted? || suspended?

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
    #   * `browser_cluster` -- {BrowserCluster.statistics}
    #   *  `:runtime`       -- Scan runtime in seconds.
    #   *  `:found_pages`   -- Number of discovered pages.
    #   *  `:audited_pages` -- Number of audited pages.
    #   *  `:current_page`  -- URL of the currently audited page.
    #   *  `:status`        -- {#status}
    #   *  `:messages`      -- {#status_messages}
    def statistics
        {
            http:            http.statistics,
            browser_cluster: BrowserCluster.statistics,
            runtime:         @start_datetime ? Time.now - @start_datetime : 0,
            found_pages:     sitemap.size,
            audited_pages:   state.audited_page_count,
            current_page:    @current_url
        }
    end

    def inspect
        stats = statistics

        s = "#<#{self.class} (#{status}) "

        s << "runtime=#{stats[:runtime]} "
        s << "found-pages=#{stats[:found_pages]} "
        s << "audited-pages=#{stats[:audited_pages]} "
        s << "issues=#{Data.issues.size} "

        if @current_url
            s << "current_url=#{@current_url.inspect} "
        end

        s << "checks=#{@checks.keys.join(',')} "
        s << "plugins=#{@plugins.keys.join(',')}"
        s << '>'
    end

    # @return    [String]
    #   Returns the version of the framework.
    def version
        Arachni::VERSION
    end

end
end
