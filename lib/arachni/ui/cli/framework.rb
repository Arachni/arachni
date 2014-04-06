=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative '../../../arachni'
require_relative 'framework/option_parser'
require_relative 'utilities'

module Arachni
module UI::CLI

# Provides a command line interface for the {Arachni::Framework}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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

        @show_command_screen = nil
        @cleanup_handler     = nil

        trap( 'INT' ) do
            hide_command_screen
            clear_screen
            shutdown
        end

        # Kick the tires and light the fires.
        run
    end

    # Outputs all available platforms and their info.
    def list_platforms
        super @framework.list_platforms
    end

    # Outputs all available checks and their info.
    def list_checks( *args )
        super @framework.list_checks( *args )
    end

    # Outputs all available reports and their info.
    def list_reports( *args )
        super @framework.list_reports( *args )
    end

    # Outputs all available reports and their info.
    def list_plugins( *args )
        super @framework.list_plugins( *args )
    end

    private

    def run
        print_status 'Initializing...'

        get_user_command

        begin
            # We may need to kill the audit so put it in a thread.
            @scan = Thread.new do
                @framework.run do
                    hide_command_screen
                    restore_output
                    clear_screen
                end
            end

            @scan.join

            # If the user requested to abort the scan, wait for the thread that
            # takes care of the clean-up to finish.
            @cleanup_handler.join if @cleanup_handler

            print_stats
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
            print_error e
            print_error_backtrace e
            exit 1
        end
    end

    def print_stats( unmute = false )
        stats = @framework.stats

        refresh_line nil, unmute
        refresh_info( "Audited #{stats[:auditmap_size]} pages.", unmute )

        if @framework.opts.scope.page_limit
            refresh_info( "Audit limited to a max of #{@framework.opts.scope.page_limit} " +
                          "pages.", unmute )
        end

        refresh_line nil, unmute

        refresh_info( "Sent #{stats[:requests]} requests.", unmute )
        refresh_info( "Received and analyzed #{stats[:responses]} responses.", unmute )
        refresh_info( 'In ' + stats[:time], unmute )

        avg = "Average: #{stats[:avg].to_s} requests/second."
        refresh_info( avg, unmute )

        refresh_line nil, unmute
        if stats[:current_page] && !stats[:current_page].empty?
            refresh_info( "Currently auditing           #{stats[:current_page]}", unmute )
        end

        refresh_info( "Burst response time total    #{stats[:curr_res_time]}", unmute )
        refresh_info( "Burst response count total   #{stats[:curr_res_cnt]} ", unmute )
        refresh_info( "Burst average response time  #{stats[:average_res_time]}", unmute )
        refresh_info( "Burst average                #{stats[:curr_avg]} requests/second", unmute )
        refresh_info( "Timed-out requests           #{stats[:time_out_count]}", unmute )
        refresh_info( "Original max concurrency     #{options.http.request_concurrency}", unmute )
        refresh_info( "Throttled max concurrency    #{stats[:max_concurrency]}", unmute )

        refresh_line nil, unmute
    end

    def print_issues( unmute = false )
        super( Data.issues.summary, unmute, &method( :restr ) )
    end

    # Handles Ctrl+C signals.
    def show_command_screen
        return if command_screen_shown?

        @only_positives_opt = only_positives?
        @@only_positives    = false

        @show_command_screen = Thread.new do
            get_user_command
            mute
            clear_screen

            while sleep 0.3
                refresh_line
                move_to_home
                refresh_info 'Results thus far:'

                begin
                    print_issues( true )
                    print_stats( true )
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
                        'Enter' => "go back to status messages",
                        'p'     => "pause the scan",
                        'r'     => "resume the scan",
                        'a'     => "abort the scan",
                        's'     => "suspend the scan to disk",
                        'g'     => "generate reports"
                    }.each do |key, action|
                        next if %w(Enter s p).include?( key ) && !@framework.scanning?
                        next if key == 'r' && !(@framework.paused? || @framework.pausing?)

                        refresh_info "  '#{key}' to #{action}."
                    end
                end

                flush
            end

            unmute
        end
    end

    def command_screen_shown?
        @show_command_screen && @show_command_screen.alive?
    end

    def refresh_line( string = nil, unmute = true )
        print_line( restr( string.to_s ), unmute )
    end

    def refresh_info( string = nil, unmute = true )
        print_info( restr( string.to_s ), unmute )
    end

    def get_user_command
        Thread.new do
            command = gets[0].strip

            # Only accept the empty/toggle-screen command when the command
            # screen is not shown.
            return get_user_command if !command_screen_shown? && !command.empty?

            case command

                # Abort
                when 'a'
                    shutdown
                    reset_command_screen

                # Pause
                when 'p'
                    return get_user_command if !@framework.scanning?
                    reset_command_screen

                    @framework.pause
                    reset_command_screen

                # Resume
                when 'r'
                    return get_user_command if !@framework.pause?
                    reset_command_screen

                    @framework.resume
                    reset_command_screen

                # Suspend
                when 's'
                    return get_user_command if !@framework.scanning?
                    reset_command_screen
                    suspend
                    # reset_command_screen

                # Generate reports.
                when 'g'
                    hide_command_screen
                    restore_output
                    @framework.reports.run( @framework.audit_store )

                # Toggle between status messages and summary screens.
                when ''
                    return get_user_command if !@framework.scanning?

                    if @show_command_screen
                        hide_command_screen
                    else
                        show_command_screen
                    end

                    restore_output
                    clear_screen

                    get_user_command

                # Invalid command.
                else
                    get_user_command
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
    end

    def restore_output
        @@only_positives = @only_positives_opt
        unmute
    end

    def suspend
        @cleanup_handler = Thread.new do
            @framework.suspend

            hide_command_screen
            restore_output
            clear_screen

            @framework.reports.run( @framework.audit_store )

            print_line

            filesize = (File.size( @framework.snapshot_path ).to_f / 2**20).round(2)
            print_info "The snapshot has been saved at: #{@framework.snapshot_path} [#{filesize}MB]"

            print_line
        end
    end

    def shutdown
        restore_output

        print_status 'Aborting...'
        print_info 'Please wait while the system cleans up.'

        killed = Queue.new
        @cleanup_handler = Thread.new do
            killed.pop

            @framework.clean_up

            hide_command_screen
            restore_output
            clear_screen

            @framework.reports.run( @framework.audit_store )
        end

        @scan.kill
        killed << true
    end

    # It parses and processes CLI options.
    #
    # Loads checks, reports, saves/loads profiles etc.
    # It basically prepares the framework before calling {Arachni::Framework#run}.
    def parse_options
        parser = OptionParser.new

        parser.authorized_by
        parser.output
        parser.scope
        parser.audit
        parser.http
        parser.checks
        parser.reports
        parser.plugins
        parser.platforms
        parser.session
        parser.profiles
        parser.browser_cluster
        parser.parse

        if options.checks.any?
            begin
                options.checks = @framework.checks.load( options.checks )
            rescue Component::Error::NotFound => e
                print_error e
                print_info 'Available checks are:'
                print_info @framework.checks.available.join( ', ' )
                print_line
                print_info 'Use the \'--list-checks\' parameter to see a ' <<
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
                @framework.plugins.load( options.plugins )
            rescue Component::Error::NotFound => e
                print_error e
                print_info 'Available plugins are:'
                print_info @framework.plugins.available.join( ', ' )
                print_line
                print_info 'Use the \'--list-plugins\' parameter to see a ' <<
                               'detailed list of all available plugins.'
                exit 1
            end
        end

        if options.reports.any?
            begin
                @framework.reports.load( options.reports.keys )
            rescue Component::Error::NotFound => e
                print_error e
                print_info 'Available reports are:'
                print_info @framework.reports.available.join( ', ' )
                print_line
                print_info 'Use the \'--list-reports\' parameter to see a' <<
                               ' detailed list of all available reports.'
                exit 1
            end
        else
            @framework.reports.load( 'stdout' )
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
                print_info 'Use the \'--list-platforms\' parameter to see a' <<
                               ' detailed list of all available platforms.'
                exit 1
            end
        end

        if !options.audit.links && !options.audit.forms &&
            !options.audit.cookies && !options.audit.headers

            print_info 'No element audit options were specified, will audit ' <<
                           'links, forms and cookies.'
            print_line

            options.audit.elements :links, :forms, :cookies
        end
    end

    def options
        Arachni::Options
    end

end
end
end
