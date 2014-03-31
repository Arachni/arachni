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

        @interrupt_handler = nil

        # Trap Ctrl+C signals.
        trap( 'INT' ) { handle_interrupt }

        # Trap SIGUSR1 signals.
        trap ( 'USR1' ) { handle_usr1_interrupt }

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

        begin
            # We may need to kill the audit so put it in a thread.
            @scan = Thread.new do
                @framework.run do
                    kill_interrupt_handler
                    clear_screen
                end

                print_stats
            end

            @scan.join

            # If the user requested to exit the scan wait for the Thread that
            # takes care of the clean-up to finish.
            @cleanup_handler.join if @cleanup_handler
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
        mapped  = stats[:sitemap_size]

        print_line( restr, unmute )

        print_info( restr( "#{progress_bar( stats[:progress], 61 )}" ), unmute )
        print_info( restr( "Est. remaining time: #{stats[:eta]}" ), unmute )

        print_line( restr, unmute )

        if stats[:current_page] && !stats[:current_page].empty?
            print_info( restr( "Crawler has discovered #{mapped} pages." ), unmute )
        else
            print_info( restr( "Crawling, discovered #{mapped} pages and counting." ), unmute )
        end

        if @framework.opts.scope.page_limit
            print_info(
                restr( "Audit limited to a max of #{@framework.opts.scope.page_limit} " +
                                      "pages." ),
                unmute
            )
        end

        print_line( restr, unmute )

        print_info( restr( "Sent #{stats[:requests]} requests." ), unmute )
        print_info( restr( "Received and analyzed #{stats[:responses]} responses." ), unmute )
        print_info( restr( 'In ' + stats[:time] ), unmute )

        avg = 'Average: ' + stats[:avg].to_s + ' requests/second.'
        print_info( restr( avg ), unmute )

        print_line( restr, unmute )
        if stats[:current_page] && !stats[:current_page].empty?
            print_info( restr( "Currently auditing" +
                                              "           #{stats[:current_page]}" ), unmute )
        end

        print_info( restr( "Burst response time total    #{stats[:curr_res_time]}" ), unmute )
        print_info( restr( "Burst response count total   #{stats[:curr_res_cnt]} " ), unmute )
        print_info( restr( "Burst average response time  #{stats[:average_res_time]}" ), unmute )
        print_info( restr( "Burst average                #{stats[:curr_avg]} requests/second" ), unmute )
        print_info( restr( "Timed-out requests           #{stats[:time_out_count]}" ), unmute )
        print_info( restr( "Original max concurrency     #{options.http.request_concurrency}" ), unmute )
        print_info( restr( "Throttled max concurrency    #{stats[:max_concurrency]}" ), unmute )

        print_line( restr, unmute )
    end

    def print_issues( unmute = false )
        super( Data.issues.summary, unmute, &method( :restr ) )
    end

    def kill_interrupt_handler
        @@only_positives = @only_positives_opt
        @interrupt_handler.exit if @interrupt_handler
        unmute
    end

    # Handles Ctrl+C signals.
    #
    # Once an interrupt has been trapped the system pauses and waits for user
    # input.
    # The user can either continue or exit.
    def handle_interrupt
        return if @interrupt_handler && @interrupt_handler.alive?

        @only_positives_opt = only_positives?
        @@only_positives    = false

        @interrupt_handler = Thread.new do
            Thread.new do
                c = gets[0]
                clear_screen
                unmute

                case c
                    when 'e'
                        @@only_positives = false
                        @interrupt_handler.kill
                        shutdown

                    when 'r'
                        @framework.reports.run( @framework.audit_store )
                end

                kill_interrupt_handler
                Thread.exit
            end

            mute
            clear_screen

            loop do
                print_line( restr, true )
                move_to_home
                print_info( restr( 'Results thus far:' ), true )

                begin
                    print_issues( true )
                    print_stats( true )
                rescue Exception => e
                    exception_jail{ raise e }
                    raise e
                end

                print_info( restr( 'Continue? (hit \'enter\' to continue, ' <<
                    '\'r\' to generate reports and \'e\' to exit)' ), true )
                flush

                ::IO::select( nil, nil, nil, 0.3 )
            end

            unmute
        end
    end

    # Handles SIGUSR1 signals.
    #
    # It will cause Arachni to create a report and shut down afterwards.
    def handle_usr1_interrupt
        print_status 'Received SIGUSR1!'
        shutdown
    end

    def shutdown
        print_status 'Exiting...'
        print_info 'Please wait while the system cleans up.'

        # Kill the audit.
        @scan.exit

        @cleanup_handler = Thread.new do
            @framework.clean_up
            @framework.reports.run( @framework.audit_store )
            print_stats
        end
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
