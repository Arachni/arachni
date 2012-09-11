=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni

require Options.dir['lib'] + 'ui/cli/output'
require Options.dir['mixins'] + 'terminal'
require Options.dir['mixins'] + 'progress_bar'
require Options.dir['arachni']

module UI

#
# Provides a command line interface for the Arachni Framework.
# Most of the logic is in the Framework class however profiles can only
# be loaded and saved at this level.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.9.1
# @see Arachni::Framework
#
class CLI
    include ::Arachni
    include Mixins::Terminal
    include Mixins::ProgressBar

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
        banner

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
        rescue Component::Manager::InvalidOptions => e
            print_error e
            print_error_backtrace e
            print_line
            exit 1
        rescue Exceptions::NoMods => e
            print_error e
            print_info "Run arachni with the '-h' parameter for help or "
            print_info "with the '--lsmod' parameter to see all available modules."
            print_line
            exit 1
        rescue Exceptions => e
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
        stats   = @arachni.stats( refresh_time )
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

        if @arachni.opts.link_count_limit > 0

            feedback = ''
            if @arachni.page_queue_total_size
                feedback = " -- excluding #{@arachni.page_queue_total_size} pages of Trainer feedback"
            end

            print_info( restr( "Audit limited to a max of #{@arachni.opts.link_count_limit} " +
                "pages#{feedback}." ),
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
            @arachni.clean_up( true )
            @arachni.reports.run( @arachni.audit_store )
            print_stats
        }
    end

    def print_issues( audit_store, unmute = false )
        print_line( restr, unmute )
        print_info( restr( "#{audit_store.issues.size} issues have been detected." ), unmute )

        print_line( restr, unmute )

        issues    = audit_store.issues
        issue_cnt = audit_store.issues.count
        issues.each.with_index do |issue, i|
            input = issue.var ? " input `#{issue.var}`" : ''
            meth  = issue.method ? " using #{issue.method}" : ''
            cnt   = "#{i + 1} |".rjust( issue_cnt.to_s.size + 2 )

            print_ok( restr(  "#{cnt} #{issue.name} at #{issue.url} in" +
                " #{issue.elem}#{input}#{meth}." ),
                unmute
            )
        end

        print_line( restr, unmute )
    end

    #
    # It parses and processes the user options.
    #
    # Loads modules, reports, saves/loads profiles etc.
    # It basically prepares the framework before calling {Arachni::Framework#run}.
    #
    def parse_opts
        if !@opts.repload && !@opts.help

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

                when 'arachni_verbose'
                    verbose

                when 'debug'
                    debug

                when 'only_positives'
                    only_positives

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

                when 'mods'
                    begin
                        @opts.mods = @arachni.modules.load( arg )
                    rescue Exceptions::ComponentNotFound => e
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
                    rescue Exceptions::ComponentNotFound => e
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
                    rescue Exceptions::ComponentNotFound => e
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

    #
    # Outputs all available modules and their info.
    #
    def lsmod
        print_line
        print_line
        print_info 'Available modules:'
        print_line

        mods = @arachni.lsmod

        i = 0
        mods.each do |info|
            print_status "#{info[:mod_name]}:"
            print_line '--------------------'

            print_line "Name:\t\t#{info[:name]}"
            print_line "Description:\t#{info[:description]}"

            if info[:elements] && info[:elements].size > 0
                print_line "Elements:\t#{info[:elements].join( ', ' ).downcase}"
            end

            print_line "Author:\t\t#{info[:author].join( ", " )}"
            print_line "Version:\t#{info[:version]}"

            if info[:references]
                print_line 'References:'
                info[:references].keys.each do |key|
                    print_info "#{key}\t\t#{info[:references][key]}"
                end
            end

            if info[:targets]
                print_line 'Targets:'

                if info[:targets].is_a?( Hash )
                    info[:targets].keys.each do |key|
                        print_info "#{key}\t\t#{info[:targets][key]}"
                    end
                else
                    info[:targets].each { |target| print_info( target ) }
                end
            end

            if info[:issue] && sploit = info[:issue][:metasploitable]
                print_line "Metasploitable:\t#{sploit}"
            end

            print_line "Path:\t#{info[:path]}"

            i += 1

            # pause every 3 modules to give the user time to read
            # (cheers to aungkhant@yehg.net for suggesting it)
            if i % 3 == 0 && i != mods.size
                print_line
                print_line 'Hit <space> <enter> to continue, any other key to exit. '

                if gets[0] != ' '
                    print_line
                    return
                end

            end

            print_line
        end

    end

    #
    # Outputs all available reports and their info.
    #
    def lsrep
        print_line
        print_line
        print_info 'Available reports:'
        print_line

        @arachni.lsrep.each do |info|
            print_status "#{info[:rep_name]}:"
            print_line '--------------------'

            print_line "Name:\t\t#{info[:name]}"
            print_line "Description:\t#{info[:description]}"

            if info[:options] && !info[:options].empty?
                print_line( "Options:\t" )

                info[:options].each do |option|
                    print_info "\t#{option.name} - #{option.desc}"
                    print_info "\tType:        #{option.type}"
                    print_info "\tDefault:     #{option.default}"
                    print_info "\tRequired?:   #{option.required?}"

                    print_line
                end
            end

            print_line "Author:\t\t#{info[:author].join( ", " )}"
            print_line "Version:\t#{info[:version] }"
            print_line "Path:\t#{info[:path]}"

            print_line
        end
    end

    #
    # Outputs all available reports and their info.
    #
    def lsplug
        print_line
        print_line
        print_info 'Available plugins:'
        print_line

        @arachni.lsplug.each do |info|
            print_status "#{info[:plug_name]}:"
            print_line '--------------------'

            print_line "Name:\t\t#{info[:name]}"
            print_line "Description:\t#{info[:description]}"

            if info[:options] && !info[:options].empty?
                print_line "Options:\t"

                info[:options].each do |option|
                    print_info "\t#{option.name} - #{option.desc}"
                    print_info "\tType:        #{option.type}"
                    print_info "\tDefault:     #{option.default}"
                    print_info "\tRequired?:   #{option.required?}"

                    print_line
                end
            end

            print_line "Author:\t\t#{info[:author].join( ', ' )}"
            print_line "Version:\t#{info[:version]}"
            print_line "Path:\t#{info[:path]}"

            print_line
        end
    end


    #
    # Loads an Arachni Framework Profile file and merges it with the
    # user supplied options.
    #
    # @param    [Array<String>]    profiles    the files to load
    #
    def load_profile( profiles )
        exception_jail{
            @opts.load_profile = nil
            profiles.each { |filename| @opts.merge!( @opts.load( filename ) ) }
        }
    end

    #
    # Saves options to an Arachni Framework Profile file.
    # The file will be appended with the {PROFILE_EXT} extension.
    #
    # @param    [String]    filename
    #
    def save_profile( filename )
        if filename = @opts.save( filename )
            print_status "Saved profile in '#{filename}'."
            print_line
        else
            banner
            print_error 'Could not save profile.'
            exit 0
        end
    end

    def print_profile
        print_info 'Running profile:'
        print_info @opts.to_args
    end

    #
    # Outputs Arachni banner.
    # Displays version number, revision number, author details etc.
    #
    # @see VERSION
    # @see REVISION
    #
    # @return [void]
    #
    def banner
        print_line BANNER
        print_line
        print_line
    end

    #
    # Outputs help/usage information.
    # Displays supported options and parameters.
    #
    # @return [void]
    #
    def usage
        print_line <<USAGE
  Usage:  arachni \[options\] url

  Supported options:


    General ----------------------

    -h
    --help                      Output this.

    -v                          Be verbose.

    --debug                     Show what is happening internally.
                                  (You should give it a shot sometime ;) )

    --only-positives            Echo positive results *only*.

    --http-req-limit=<integer>  Concurrent HTTP requests limit.
                                  (Default: #{@opts.http_req_limit})
                                  (Be careful not to kill your server.)
                                  (*NOTE*: If your scan seems unresponsive try lowering the limit.)

    --http-timeout=<integer>    HTTP request timeout in milliseconds.

    --cookie-jar=<filepath>     Netscape HTTP cookie file, use curl to create it.

    --cookie-string='<name>=<value>; <name2>=<value2>'

                                Cookies, as a string, to be sent to the web application.

    --user-agent=<string>       Specify user agent.

    --custom-header='<name>=<value>'

                                Specify custom headers to be included in the HTTP requests.
                                (Can be used multiple times.)

    --authed-by=<string>        Who authorized the scan, include name and e-mail address.
                                  (It'll make it easier on the sys-admins during log reviews.)
                                  (Will be appended to the user-agent string.)

    --login-check-url=<url>     A URL used to verify that the scanner is still logged in to the web application.
                                  (Requires 'login-check-pattern'.)

    --login-check-pattern=<regexp>

                                A pattern used against the body of the 'login-check-url' to verify that the scanner is still logged in to the web application.
                                  (Requires 'login-check-url'.)

    Profiles -----------------------

    --save-profile=<filepath>   Save the current run profile/options to <filepath>.

    --load-profile=<filepath>   Load a run profile from <filepath>.
                                  (Can be used multiple times.)
                                  (You can complement it with more options, except for:
                                      * --modules
                                      * --redundant)

    --show-profile              Will output the running profile as CLI arguments.


    Crawler -----------------------

    -e <regexp>
    --exclude=<regexp>          Exclude urls matching <regexp>.
                                  (Can be used multiple times.)

    -i <regexp>
    --include=<regexp>          Include *only* urls matching <regex>.
                                  (Can be used multiple times.)

    --redundant=<regexp>:<limit>

                                Limit crawl on redundant pages like galleries or catalogs.
                                  (URLs matching <regexp> will be crawled <limit> amount of times.)
                                  (Can be used multiple times.)

    --auto-redundant=<limit>    Only follow <limit> amount of URLs with identical query parameter names.
                                  (Default: inf)
                                  (Will default to 10 if no value has been specified.)

    -f
    --follow-subdomains         Follow links to subdomains.
                                  (Default: off)

    --depth=<integer>           Directory depth limit.
                                  (Default: inf)
                                  (How deep Arachni should go into the site structure.)

    --link-count=<integer>      How many links to follow.
                                  (Default: inf)

    --redirect-limit=<integer>  How many redirects to follow.
                                  (Default: #{@opts.redirect_limit})

    --extend-paths=<filepath>   Add the paths in <file> to the ones discovered by the crawler.
                                  (Can be used multiple times.)

    --restrict-paths=<filepath> Use the paths in <file> instead of crawling.
                                  (Can be used multiple times.)


    Auditor ------------------------

    -g
    --audit-links               Audit links.

    -p
    --audit-forms               Audit forms.

    -c
    --audit-cookies             Audit cookies.

    --exclude-cookie=<name>     Cookie to exclude from the audit by name.
                                  (Can be used multiple times.)

    --exclude-vector=<name>     Input vector (parameter) not to audit by name.
                                  (Can be used multiple times.)

    --audit-headers             Audit HTTP headers.
                                  (*NOTE*: Header audits use brute force.
                                   Almost all valid HTTP request headers will be audited
                                   even if there's no indication that the web app uses them.)
                                  (*WARNING*: Enabling this option will result in increased requests,
                                   maybe by an order of magnitude.)

    Coverage -----------------------

    --audit-cookies-extensively Submit all links and forms of the page along with the cookie permutations.
                                  (*WARNING*: This will severely increase the scan-time.)

    --fuzz-methods              Audit links, forms and cookies using both GET and POST requests.
                                  (*WARNING*: This will severely increase the scan-time.)

    --exclude-binaries          Exclude non text-based pages from the audit.
                                  (Binary content can confuse recon modules that perform pattern matching.)

    Modules ------------------------

    --lsmod=<regexp>            List available modules based on the provided regular expression.
                                  (If no regexp is provided all modules will be listed.)
                                  (Can be used multiple times.)


    -m <modname,modname..>
    --modules=<modname,modname..>

                                Comma separated list of modules to load.
                                  (Modules are referenced by their filename without the '.rb' extension, use '--lsmod' to list all.
                                   Use '*' as a module name to deploy all modules or as a wildcard, like so:
                                      xss*   to load all xss modules
                                      sqli*  to load all sql injection modules
                                      etc.

                                   You can exclude modules by prefixing their name with a minus sign:
                                      --modules=*,-backup_files,-xss
                                   The above will load all modules except for the 'backup_files' and 'xss' modules.

                                   Or mix and match:
                                      -xss*   to unload all xss modules.)


    Reports ------------------------

    --lsrep=<regexp>            List available reports based on the provided regular expression.
                                  (If no regexp is provided all reports will be listed.)
                                  (Can be used multiple times.)

    --repload=<filepath>        Load audit results from an '.afr' report file.
                                    (Allows you to create new reports from finished scans.)

    --report='<report>:<optname>=<val>,<optname2>=<val2>,...'

                                <report>: the name of the report as displayed by '--lsrep'
                                  (Reports are referenced by their filename without the '.rb' extension, use '--lsrep' to list all.)
                                  (Default: stdout)
                                  (Can be used multiple times.)


    Plugins ------------------------

    --lsplug=<regexp>           List available plugins based on the provided regular expression.
                                  (If no regexp is provided all plugins will be listed.)
                                  (Can be used multiple times.)

    --plugin='<plugin>:<optname>=<val>,<optname2>=<val2>,...'

                                <plugin>: the name of the plugin as displayed by '--lsplug'
                                  (Plugins are referenced by their filename without the '.rb' extension, use '--lsplug' to list all.)
                                  (Can be used multiple times.)


    Proxy --------------------------

    --proxy=<server:port>       Proxy address to use.

    --proxy-auth=<user:passwd>  Proxy authentication credentials.

    --proxy-type=<type>         Proxy type; can be http, http_1_0, socks4, socks5, socks4a
                                  (Default: http)


USAGE
    end

end

end
end
