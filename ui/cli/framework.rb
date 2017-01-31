=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative '../../lib/arachni'
require_relative 'framework/option_parser'
require_relative 'utilities'

module Arachni
module UI::CLI

# Provides a command line interface for the {Arachni::Framework}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.3
class Framework
    include UI::Output
    include Utilities

    # @return [Framework]
    attr_reader :framework

    # Initializes the command line interface and the {Framework}.
    def initialize
        # Instantiate the big-boy!
        @framework = Arachni::Framework.new

        parse_options

        # Reset the framework's HTTP interface so that options will take effect.
        @framework.http.reset

        @framework.reset_trainer

        @show_command_screen = nil
        @cleanup_handler     = nil

        if Signal.list.include?( 'USR1' )
            # Step into a pry session for debugging.
            trap( 'USR1' ) do
                Thread.new do
                    require 'pry'

                    mute
                    clear_screen

                    pry

                    clear_screen
                    unmute
                end
            end
        end

        trap( 'INT' ) do
            hide_command_screen
            clear_screen
            shutdown
        end

        # Kick the tires and light the fires.
        run
    end

    private

    def run
        print_status 'Initializing...'

        # Won't work properly on MS Windows or when running in background.
        get_user_command if !Arachni.windows? && !@daemon_friendly

        begin
            # We may need to kill the audit so put it in a thread.
            @scan = Thread.new do
                @framework.run do
                    hide_command_screen
                    restore_output_options
                    clear_screen
                end

                @timeout_supervisor.kill if @timeout_supervisor
            end

            if @timeout
                @timeout_supervisor = Thread.new do
                    sleep @timeout

                    if @timeout_suspend
                        print_error 'Timeout has been reached, suspending.'
                        suspend
                    else
                        print_error 'Timeout has been reached, shutting down.'
                        shutdown
                    end
                end
            end

            @timeout_supervisor.join if @timeout_supervisor
            @scan.join

            # If the user requested to abort the scan, wait for the thread
            # that takes care of the clean-up to finish.
            if @cleanup_handler
                @cleanup_handler.join
            else
                generate_reports
            end

            if has_error_log?
                print_info "The scan has logged errors: #{error_logfile}"
            end

            print_statistics
        rescue Component::Options::Error::Invalid => e
            print_error e
            print_line
            exit 1
        rescue Arachni::Error => e
            print_error e
            print_info "Run arachni with the '-h' parameter for help."
            print_line
            exit 1
        rescue Exception => e
            print_exception e
            exit 1
        end
    end

    def print_statistics( unmute = false )
        statistics = @framework.statistics

        http            = statistics[:http]
        browser_cluster = statistics[:browser_cluster]

        refresh_line nil, unmute
        refresh_info( "Audited #{statistics[:audited_pages]} page snapshots.", unmute )

        if @framework.options.scope.page_limit
            refresh_info( 'Audit limited to a max of ' <<
                "#{@framework.options.scope.page_limit} pages.", unmute )
        end

        refresh_line nil, unmute

        refresh_info( "Duration: #{seconds_to_hms( statistics[:runtime] )}", unmute )

        res_req = "#{statistics[:http][:response_count]}/#{statistics[:http][:request_count]}"
        refresh_info( "Processed #{res_req} HTTP requests.", unmute )

        avg = "-- #{http[:total_responses_per_second].round(3)} requests/second."
        refresh_info( avg, unmute )

        jobs = "#{browser_cluster[:completed_job_count]}/#{browser_cluster[:queued_job_count]}"
        refresh_info( "Processed #{jobs} browser jobs.", unmute )

        jobsps = "-- #{browser_cluster[:seconds_per_job].round(3)} second/job."
        refresh_info( jobsps, unmute )

        refresh_line nil, unmute
        if !statistics[:current_page].to_s.empty?
            refresh_info( "Currently auditing          #{statistics[:current_page]}", unmute )
        end

        refresh_info( "Burst response time sum     #{http[:burst_response_time_sum].round(3)} seconds", unmute )
        refresh_info( "Burst response count        #{http[:burst_response_count]}", unmute )
        refresh_info( "Burst average response time #{http[:burst_average_response_time].round(3)} seconds", unmute )
        refresh_info( "Burst average               #{http[:burst_responses_per_second].round(3)} requests/second", unmute )
        refresh_info( "Timed-out requests          #{http[:time_out_count]}", unmute )
        refresh_info( "Original max concurrency    #{options.http.request_concurrency}", unmute )
        refresh_info( "Throttled max concurrency   #{http[:max_concurrency]}", unmute )

        refresh_line nil, unmute
    end

    def print_issues( unmute = false )
        super( Data.issues.all, unmute )
    end

    # Handles Ctrl+C signals.
    def show_command_screen
        return if command_screen_shown?

        @show_command_screen = Thread.new do
            clear_screen
            get_user_command
            mute

            loop do
                empty_screen

                refresh_info 'Results thus far:'

                begin
                    print_issues( true )
                    print_statistics( true )
                rescue Exception => e
                    exception_jail{ raise e }
                    raise e
                end

                refresh_info "Status: #{@framework.status.to_s.capitalize}"
                @framework.status_messages.each do |message|
                    refresh_info "  #{message}"
                end

                if !@framework.suspend?
                    refresh_info
                    refresh_info 'Hit:'

                    {
                        'Enter' => 'go back to status messages',
                        'p'     => 'pause the scan',
                        'r'     => 'resume the scan',
                        'a'     => 'abort the scan',
                        's'     => 'suspend the scan to disk',
                        'g'     => 'generate a report',
                        'v'     => "#{verbose? ? 'dis' : 'en'}able verbose messages",
                        'd'     => "#{debug? ? 'dis' : 'en'}able debugging messages.\n" <<
                            "#{' ' * 11}(You can set it to the desired level by sending d[1-4]," <<
                            " current level is #{debug_level})"
                    }.each do |key, action|
                        next if %w(Enter s p).include?( key ) && !@framework.scanning?
                        next if key == 'r' && !(@framework.paused? || @framework.pausing?)

                        refresh_info "  '#{key}' to #{action}."
                    end
                end

                flush
                mute
                sleep 1
            end
        end
    end

    def command_screen_shown?
        @show_command_screen && @show_command_screen.alive?
    end

    def refresh_line( string = nil, unmute = true )
        print_line( string.to_s, unmute )
    end

    def refresh_info( string = nil, unmute = true )
        print_info( string.to_s, unmute )
    end

    def get_user_command
        Thread.new do
            command = gets.strip

            get_user_command

            # Only accept the empty/toggle-screen command when the command
            # screen is not shown.
            return if !command_screen_shown? && !command.empty?

            case command

                # Abort
                when 'a'
                    shutdown

                # Pause
                when 'p'
                    return if !@framework.scanning?

                    @pause_id = @framework.pause

                # Resume
                when 'r'
                    return if !@pause_id
                    @framework.resume @pause_id
                    @pause_id = nil

                # Suspend
                when 's'
                    return if !@framework.scanning?
                    suspend

                # Generate reports.
                when 'g'
                    hide_command_screen
                    generate_reports
                    restore_output_options

                # Toggle verbosity.
                when 'v'
                    hide_command_screen
                    verbose? ? verbose_off : verbose_on

                # Toggle debugging messages.
                when /d(\d?)/
                    hide_command_screen

                    if (level = Regexp.last_match[1]).empty?
                        debug? ? debug_off : debug_on
                    else
                        debug_on( level.to_i )
                    end

                # Toggle between status messages and command screens.
                when ''
                    if @show_command_screen
                        hide_command_screen
                    else
                        capture_output_options
                        show_command_screen
                    end

                    empty_screen
            end
        end
    end

    def reset_command_screen
        hide_command_screen
        show_command_screen
    end

    def hide_command_screen
        @show_command_screen.kill if @show_command_screen
        @show_command_screen = nil
        restore_output_options
    end

    def capture_output_options
        @only_positives_opt = only_positives?
        @@only_positives    = false
    end

    def restore_output_options
        @@only_positives = @only_positives_opt
        unmute
    end

    def suspend
        @cleanup_handler = Thread.new do
            exception_jail do
                @framework.suspend

                hide_command_screen
                clear_screen

                capture_output_options

                generate_reports

                filesize = (File.size( @framework.snapshot_path ).to_f / 2**20).round(2)
                print_info "Snapshot saved at: #{@framework.snapshot_path} [#{filesize}MB]"

                print_line
            end
        end
    end

    def shutdown
        @timeout_supervisor.kill if @timeout_supervisor && Thread.current != @timeout_supervisor
        capture_output_options

        print_status 'Aborting...'
        print_info 'Please wait while the system cleans up.'

        killed = Queue.new
        @cleanup_handler = Thread.new do
            exception_jail do
                killed.pop

                @framework.clean_up

                hide_command_screen
                restore_output_options
                clear_screen

                generate_reports
            end
        end

        @scan.kill
        killed << true
    end

    def generate_reports
        capture_output_options

        report = @framework.report

        @framework.reporters.run :stdout, report

        filepath = report.save( options.datastore.report_path )
        filesize = (File.size( filepath ).to_f / 2**20).round(2)

        print_line
        print_info "Report saved at: #{filepath} [#{filesize}MB]"
    end

    # It parses and processes CLI options.
    #
    # Loads checks, reports, saves/loads profiles etc.
    # It basically prepares the framework before calling {Arachni::Framework#run}.
    def parse_options
        parser = OptionParser.new

        parser.daemon_friendly
        parser.authorized_by
        parser.output
        parser.scope
        parser.audit
        parser.input
        parser.http
        parser.checks
        parser.plugins
        parser.platforms
        parser.session
        parser.profiles
        parser.browser_cluster
        parser.report
        parser.snapshot
        parser.timeout
        parser.timeout_suspend
        parser.parse

        @timeout         = parser.get_timeout
        @timeout_suspend = parser.timeout_suspend?

        @daemon_friendly = parser.daemon_friendly?

        if options.checks.any?
            begin
                options.checks = @framework.checks.load( options.checks )
            rescue Component::Error::NotFound => e
                print_error e
                print_info 'Available checks are:'
                print_info @framework.checks.available.join( ', ' )
                print_line
                print_info 'Use the \'--checks-list\' parameter to see a ' <<
                               'detailed list of all available checks.'
                exit 1
            end
        else
            print_info 'No checks were specified, loading all.'
            options.checks = @framework.checks.load( '*' )
        end

        @framework.plugins.load_defaults
        if options.plugins.any?
            begin
                @framework.plugins.load( options.plugins.keys )
            rescue Component::Error::NotFound => e
                print_error e
                print_info 'Available plugins are:'
                print_info @framework.plugins.available.join( ', ' )
                print_line
                print_info 'Use the \'--plugins-list\' parameter to see a ' <<
                               'detailed list of all available plugins.'
                exit 1
            end
        end

        if options.platforms.any?
            begin
                Platform::Manager.new( options.platforms )
            rescue Platform::Error::Invalid => e
                options.platforms.clear
                print_error e
                print_info 'Available platforms are:'
                print_info Platform::Manager.new.valid.to_a.join( ', ' )
                print_line
                print_info 'Use the \'--platforms-list\' parameter to see a' <<
                               ' detailed list of all available platforms.'
                exit 1
            end
        end

        if !options.audit.links? && !options.audit.forms? &&
            !options.audit.cookies? && !options.audit.headers? &&
            !options.audit.link_templates? && !options.audit.jsons? &&
            !options.audit.xmls? && !options.audit.ui_inputs? &&
            !options.audit.ui_forms?

            print_info 'No element audit options were specified, will audit ' <<
                           'links, forms, cookies, UI inputs, UI forms, JSONs and XMLs.'
            print_line

            options.audit.elements :links, :forms, :cookies, :ui_inputs,
                                   :ui_forms, :jsons, :xmls
        end
    end

    def options
        Arachni::Options
    end

end
end
end
