=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

require Options.dir['arachni']
require Options.dir['lib'] + 'ui/cli/utilities'

module UI

#
# Provides a command line interface for the Arachni Framework.
#
# Most of the logic is in the Framework class however profiles can only
# be loaded and saved at this level.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2
# @see Arachni::Framework
#
class CLI
    include ::Arachni

    # the output interface for CLI
    include UI::Output
    include Utilities

    # @return    [Options]
    attr_reader :opts

    #
    # Initializes the command line interface and the framework
    #
    # @param    [Options]    opts
    #
    def initialize( opts )
        @opts = opts

        # if we have a load profile load it and merge it with the
        # user supplied options
        if @opts.load_profile
            load_profile( @opts.load_profile )
        end

        #
        # the stdout report is the default one for the CLI,
        # each UI should have it's own default
        #
        # always load the stdout report unless the user requested
        # to see a list of the available reports
        #
        # *do not* forget this check, otherwise the reports registry
        # will desync
        #
        if @opts.reports.empty? && @opts.lsrep.empty?
            @opts.reports['stdout'] = {}
        end

        # instantiate the big-boy!
        @arachni = Framework.new( @opts )

        # echo the banner
        print_banner

        # work on the user supplied arguments
        parse_opts

        @interrupt_handler = nil

        # trap Ctrl+C interrupts
        trap( 'INT' ) { handle_interrupt }

        # trap SIGUSR1 interrupts
        trap ( 'USR1' ) { handle_usr1_interrupt }
    end

    #
    # Runs Arachni
    #
    def run
        print_status 'Initialising...'

        begin
            # we may need to kill the audit so put it in a thread
            @audit = Thread.new {
                # start the show!
                @arachni.run {
                    kill_interrupt_handler
                    clear_screen
                }
                print_stats
            }

            @audit.join

            # if the user requested to exit the scan wait for the
            # Thread that takes care of the clean-up to finish
            @exit_handler.join if @exit_handler
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

    private

    def print_stats( refresh_time = false, unmute = false )
        stats = @arachni.stats( refresh_time )
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

        if @arachni.opts.link_count_limit
            print_info(
                restr( "Audit limited to a max of #{@arachni.opts.link_count_limit} " +
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
        print_info( restr( "Original max concurrency     #{@opts.http_req_limit}" ), unmute )
        print_info( restr( "Throttled max concurrency    #{stats[:max_concurrency]}" ), unmute )

        print_line( restr, unmute )
    end

    def print_issues( audit_store, unmute = false )
        super( audit_store.issues, unmute, &method( :restr ) )
    end

    def kill_interrupt_handler
        @@only_positives = @only_positives_opt
        @interrupt_handler.exit if @interrupt_handler
        unmute
    end

    #
    # Handles Ctrl+C interrupts
    #
    # Once an interrupt has been trapped the system pauses and waits
    # for user input.
    # The user can either continue or exit.
    #
    # The interrupt will be handled after a module has finished.
    #
    def handle_interrupt
        return if @interrupt_handler && @interrupt_handler.alive?

        @only_positives_opt = only_positives?
        @@only_positives = false

        @interrupt_handler = Thread.new {

             Thread.new {

                c = gets[0]
                clear_screen
                unmute
                case c

                    when 'e'
                        @@only_positives = false
                        @interrupt_handler.kill
                        shutdown

                    when 'r'
                        @arachni.reports.run( @arachni.audit_store )
                end

                kill_interrupt_handler
                Thread.exit
            }

            mute
            clear_screen
            loop do

                print_line( restr, true )
                move_to_home
                print_info( restr( 'Results thus far:' ), true )

                begin
                    print_issues( @arachni.audit_store, true )
                    print_stats( true, true )
                rescue Exception => e
                    exception_jail{ raise e }
                    raise e
                end

                print_info( restr( 'Continue? (hit \'enter\' to continue, \'r\' to generate reports and \'e\' to exit)' ), true )
                flush

                ::IO::select( nil, nil, nil, 0.3 )
            end

            unmute
        }

    end

    #
    # Handles SIGUSR1 system calls
    #
    # It will cause Arachni to create a report and shut down afterwards
    #
    def handle_usr1_interrupt
        print_status 'Received SIGUSR1!'
        shutdown
    end

    def shutdown
        print_status 'Exiting...'
        print_info 'Please wait while the system cleans up.'

        # kill the audit
        @audit.exit

        @exit_handler = Thread.new {
            @arachni.clean_up
            @arachni.reports.run( @arachni.audit_store )
            print_stats
        }
    end

    #
    # It parses and processes the user options.
    #
    # Loads modules, reports, saves/loads profiles etc.
    # It basically prepares the framework before calling {Arachni::Framework#run}.
    #
    def parse_opts
        if !@opts.repload && !@opts.help && !@opts.show_version?

            if !@opts.mods || @opts.mods.empty?
                print_info 'No modules were specified.'
                print_info ' -> Will run all mods.'
                print_line

                @opts.mods = '*'
            end

            if !@opts.audit_links && !@opts.audit_forms && !@opts.audit_cookies &&
                !@opts.audit_headers

                print_info 'No audit options were specified.'
                print_info ' -> Will audit links, forms and cookies.'
                print_line

                @opts.audit :links, :forms, :cookies
            end

        end

        @arachni.plugins.load_defaults
        @opts.to_hash.each do |opt, arg|

            case opt.to_s

                when 'help'
                    usage
                    exit 0

                when 'version'
                    print_version
                    exit 0

                when 'arachni_verbose'
                    verbose

                when 'debug'
                    debug

                when 'only_positives'
                    only_positives

                when 'lsplat'
                    lsplat
                    exit 0

                when 'lsmod'
                    next if arg.empty?
                    lsmod
                    exit 0

                when 'lsplug'
                    next if arg.empty?
                    lsplug
                    exit 0

                when 'lsrep'
                    next if arg.empty?
                    lsrep
                    exit 0

                when 'show_profile'
                    print_profile
                    exit 0

                when 'save_profile'
                    exception_jail{ save_profile( arg ) }
                    exit 0

                when 'platforms'
                    begin
                        Platform::Manager.new( arg )
                    rescue Platform::Error::Invalid => e
                        @opts.platforms.clear
                        print_error e
                        print_info 'Available platforms are:'
                        print_info Platform::Manager.new.valid.to_a.join( ', ' )
                        print_line
                        print_info 'Use the \'--lsplat\' parameter to see a detailed list of all available platforms.'
                        exit 1
                    end

                when 'mods'
                    begin
                        @opts.mods = @arachni.modules.load( arg )
                    rescue Component::Error::NotFound => e
                        print_error e
                        print_info 'Available modules are:'
                        print_info @arachni.modules.available.join( ', ' )
                        print_line
                        print_info 'Use the \'--lsmod\' parameter to see a detailed list of all available modules.'
                        exit 1
                    end

                when 'reports'
                    begin
                        @arachni.reports.load( arg.keys )
                    rescue Component::Error::NotFound => e
                        print_error e
                        print_info 'Available reports are:'
                        print_info @arachni.reports.available.join( ', ' )
                        print_line
                        print_info 'Use the \'--lsrep\' parameter to see a detailed list of all available reports.'
                        exit 1
                    end

                when 'plugins'
                    begin
                        @arachni.plugins.load( arg.keys )
                    rescue Component::Error::NotFound => e
                        print_error e
                        print_info 'Available plugins are:'
                        print_info @arachni.plugins.available.join( ', ' )
                        print_line
                        print_info 'Use the \'--lsplug\' parameter to see a detailed list of all available plugins.'
                        exit 1
                    end

                when 'repload'
                    begin
                        @arachni.reports.run( AuditStore.load( arg ), false )
                    rescue ::Errno::ENOENT
                        print_error "Report file '#{arg}' doesn't exist."
                        exit 1
                    rescue => e
                        print_error e
                        print_error_backtrace e
                    end
                    exit
            end

        end

        # Check for missing url
        if !@opts.url &&  !@opts.repload
            print_error 'Missing url argument.'
            exit 1
        end

    end

    def print_version
        print_line "Arachni #{Arachni::VERSION} (#{RUBY_ENGINE} #{RUBY_VERSION}" +
            "p#{RUBY_PATCHLEVEL}) [#{RUBY_PLATFORM}]"
    end

    # Outputs all available platforms and their info.
    def lsplat
        super @arachni.lsplat
    end

    # Outputs all available modules and their info.
    def lsmod
        super @arachni.lsmod
    end

    # Outputs all available reports and their info.
    def lsrep
        super @arachni.lsrep
    end

    # Outputs all available reports and their info.
    def lsplug
        super @arachni.lsplug
    end

end

end
end
