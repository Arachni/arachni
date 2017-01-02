=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

require Options.paths.mixins + 'terminal'
require Options.paths.lib + 'rpc/client/instance'
require Options.paths.lib + 'utilities'
require_relative '../../utilities'
require Options.paths.lib + 'framework'

module UI::CLI
module RPC
module Client

# Provides a command-line RPC client/interface for an {RPC::Server::Instance}.
#
# This interface should be your first stop when looking into using/creating your
# own RPC client.
#
# Of course, you don't need to have access to the framework or any other Arachni
# class for your own client, this is used here just to provide some other info
# to the user.
#
# However, in contrast with everywhere else in the system (where RPC operations
# are asynchronous), this interface operates in blocking mode as its simplicity
# does not warrant the extra complexity of asynchronous calls.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Instance
    include Arachni::UI::Output
    include UI::CLI::Utilities

    include Support::Mixins::Terminal

    attr_reader :error_log_file
    attr_reader :framework

    # @param    [Arachni::Options]  options
    # @param    [RPC::Client::Instance] instance    Instance to control.
    # @param    [Integer]  timeout
    def initialize( options, instance, timeout = nil )
        @options  = options
        @instance = instance
        @timeout  = timeout

        clear_screen
        move_to_home

        # We don't need the framework for much, in this case only for report
        # generation, version number etc.
        @framework = Arachni::Framework.new( @options )
        @issues    = []
    end

    def run
        timeout_time = Time.now + @timeout.to_i
        timed_out    = false

        begin
            # Start the show!
            @instance.service.scan prepare_rpc_options

            while busy?
                if @timeout && Time.now >= timeout_time
                    timed_out = true
                    break
                end

                print_progress
                sleep 5
                refresh_progress
            end
        rescue Interrupt
        rescue => e
            print_exception e
        end

        report_and_shutdown

        return if !timed_out
        print_error 'Timeout was reached.'
    end

    private

    def print_progress
        empty_screen

        print_banner

        print_issues
        print_line

        print_statistics
        print_line

        if has_errors?
            print_bad "This scan has encountered errors, see: #{error_log_file}"
            print_line
        end

        print_info "('Ctrl+C' aborts the scan and retrieves the report)"
        print_line

        flush
    end

    def has_errors?
        !!error_log_file
    end

    def progress
        @progress or refresh_progress
    end

    def refresh_progress
        @error_messages_cnt ||= 0
        @issue_digests      ||= []

        progress = @instance.service.native_progress(
            with:    [ :instances, :issues, errors: @error_messages_cnt ],
            without: [ issues: @issue_digests ]
        )

        return if !progress

        @progress = progress
        @issues  |= @progress[:issues]

        @issues = @issues.sort_by(&:digest).sort_by(&:severity).reverse

        # Keep issue digests and error messages in order to ask not to retrieve
        # them on subsequent progress calls in order to save bandwidth.
        @issue_digests  |= @progress[:issues].map( &:digest )

        if @progress[:errors].any?
            error_log_file = @instance.url.gsub( ':', '_' )
            @error_log_file = "#{error_log_file}.error.log"

            File.open( @error_log_file, 'a' ) { |f| f.write @progress[:errors].join( "\n" ) }

            @error_messages_cnt += @progress[:errors].size
        end

        @progress
    end

    def busy?
        !!progress[:busy]
    end

    # Laconically output the discovered issues.
    #
    # This method is used during a pause.
    def print_issues
        super @issues
    end

    def prepare_rpc_options
        if @options.dispatcher.grid? && @options.spawns <= 0
            print_error "The 'spawns' option needs to be more than 1 for Grid scans."
            exit 1
        end

        if (@options.dispatcher.grid? || @options.spawns > 0) && @options.scope.restrict_paths.any?
            print_error "Option 'scope_restrict_paths' is not supported when in High-Performance mode."
            exit 1
        end

        # No checks have been specified, set the mods to '*' (all).
        if @options.checks.empty?
            @options.checks = ['*']
        end

        if !@options.audit.links? && !@options.audit.forms? &&
            !@options.audit.cookies? && !@options.audit.headers? &&
            !@options.audit.link_templates? && !@options.audit.jsons? &&
            !@options.audit.xmls?

            print_info 'No element audit options were specified, will audit ' <<
                           'links, forms, cookies, JSONs and XMLs.'
            print_line

            @options.audit.elements :links, :forms, :cookies, :jsons, :xmls
        end

        if @options.http.cookie_jar_filepath
            @options.http.cookies =
                parse_cookie_jar( @options.http.cookie_jar_filepath )
        end

        opts = @options.to_rpc_data.deep_clone
        opts['spawns'] = @options.spawns

        @framework.plugins.default.each do |plugin|
            opts['plugins'][plugin.to_s] ||= {}
        end

        opts
    end

    # Grabs the report from the RPC server and runs the selected Arachni report.
    def report_and_shutdown
        print_status 'Shutting down and retrieving the report, please wait...'

        report = @instance.service.native_abort_and_report
        shutdown

        @framework.reporters.run :stdout, report

        filepath = report.save( @options.datastore.report_path )
        filesize = (File.size( filepath ).to_f / 2**20).round(2)

        print_info "Report saved at: #{filepath} [#{filesize}MB]"

        print_line
        print_statistics
        print_line
    end

    def shutdown
        @instance.service.shutdown
    end

    def statistics
        progress[:statistics]
    end

    def status
        progress[:status]
    end

    def print_statistics
        print_info "Status: #{status.to_s.capitalize}"

        print_info "Discovered #{statistics[:found_pages]} pages thus far."
        print_line

        http = statistics[:http]
        print_info "Sent #{http[:request_count]} requests."
        print_info "Received and analyzed #{http[:response_count]} responses."
        print_info( "In #{seconds_to_hms( statistics[:runtime] )}" )
        print_info "Average: #{http[:total_responses_per_second]} requests/second."

        print_line
        if statistics[:current_pages]
            print_info 'Currently auditing:'

            statistics[:current_pages].each.with_index do |url, i|
                cnt = "[#{i + 1}]".rjust( statistics[:current_pages].size.to_s.size + 4 )

                if url.to_s.empty?
                    print_info "#{cnt} Idle"
                else
                    print_info "#{cnt} #{url}"
                end
            end

            print_line
        else
            print_info "Currently auditing           #{statistics[:current_page]}"
        end

        print_info "Burst response time sum      #{http[:burst_response_time_sum]} seconds"
        print_info "Burst response count total   #{http[:burst_response_count]}"
        print_info "Burst average response time  #{http[:burst_average_response_time]} seconds"
        print_info "Burst average                #{http[:burst_responses_per_second]} requests/second"
        print_info "Timed-out requests           #{http[:time_out_count]}"
        print_info "Original max concurrency     #{@options.http.request_concurrency * (@options.spawns.to_i + 1)}"
        print_info "Throttled max concurrency    #{http[:max_concurrency]}"
    end

    def parse_cookie_jar( jar )
        # make sure that the provided cookie-jar file exists
        if !File.exist?( jar )
            fail Arachni::Exceptions::NoCookieJar, "Cookie-jar '#{jar}' doesn't exist."
        end

        Arachni::Element::Cookie.from_file( @options.url, jar ).inject({}) do |h, e|
            h.merge!( e.simple ); h
        end
    end

end

end
end
end
end
