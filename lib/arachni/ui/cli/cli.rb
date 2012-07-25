=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end


module Arachni

require Options.instance.dir['lib'] + 'ui/cli/output'
require Options.instance.dir['mixins'] + 'terminal'
require Options.instance.dir['mixins'] + 'progress_bar'
require Options.instance.dir['arachni']

module UI

#
# Arachni::UI:CLI class
#
# Provides a command line interface for the Arachni Framework.<br/>
# Most of the logic is in the Framework class however profiles can only<br/>
# be loaded and saved at this level.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.9
# @see Arachni::Framework
#
class CLI
    include ::Arachni::Mixins::Terminal
    include ::Arachni::Mixins::ProgressBar

    #
    # Instance options
    #
    # @return    [Options]
    #
    attr_reader :opts

    # the output interface for CLI
    include Arachni::UI::Output
    include Arachni::Module::Utilities

    #
    # Initializes the command line interface and the framework
    #
    # @param    [Options]    opts
    #
    def initialize( opts )

        @opts = opts

        # if we have a load profile load it and merge it with the
        # user supplied options
        if( @opts.load_profile )
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
        if( @opts.reports.empty? && @opts.lsrep.empty? )
            @opts.reports['stdout'] = {}
        end

        # instantiate the big-boy!
        @arachni = Arachni::Framework.new( @opts  )


        # echo the banner
        banner( )

        # work on the user supplied arguments
        parse_opts( )

        @interrupt_handler = nil

        # trap Ctrl+C interrupts
        trap( 'INT' ) { handle_interrupt( ) }

	      # trap SIGUSR1 interrupts
      	trap( 'USR1' ) { handle_usr1_interrupt( ) }
    end

    #
    # Runs Arachni
    #
    def run( )

        print_status( 'Initing...' )

        begin
            # we may need to kill the audit so put it in a thread
            @audit = Thread.new {
                # start the show!
                @arachni.run {
                    kill_interrupt_handler
                    clear_screen!
                }
                print_stats
            }

            @audit.join

            # if the user requested to exit the scan wait until the
            # Thread that takes care of the clean up to finish
            @exit_handler.join if @exit_handler
        rescue Arachni::Exceptions::NoMods => e
            print_error( e.to_s )
            print_info( "Run arachni with the '-h' parameter for help or " )
            print_info( "with the '--lsmod' parameter to see all available modules." )
            print_line
            exit 0
        rescue Arachni::Exceptions => e
            print_error( e.to_s )
            print_info( "Run arachni with the '-h' parameter for help." )
            print_line
            exit 0
        rescue Exception => e
            exception_jail{ raise e }
            exit 0
        end
    end

    private

    def print_stats( refresh_time = false, unmute = false )

        stats   = @arachni.stats( refresh_time )

        audited = stats[:auditmap_size]
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
        unmute!
    end



    #
    # Handles Ctrl+C interrupts
    #
    # Once an interrupt has been trapped the system pauses and waits
    # for user input. <br/>
    # The user can either continue or exit.
    #
    # The interrupt will be handled after a module has finished.
    #
    def handle_interrupt
        return if @interrupt_handler && @interrupt_handler.alive?

        @only_positives_opt = only_positives_opt = only_positives?
        @@only_positives = false

        @interrupt_handler = Thread.new {

             Thread.new {

                c = gets[0]
                clear_screen!
                unmute!
                case c

                    when 'e'
                        @@only_positives = false
                        @interrupt_handler.kill

                        print_status( 'Exiting...' )
                        print_info( 'Please wait while the system cleans up.' )

                        # kill the audit
                        @audit.exit

                        @exit_handler = Thread.new {
                            @arachni.clean_up!( true )
                            @arachni.reports.run( @arachni.audit_store( true ) )
                            print_stats
                        }

                    when 'r'
                        @arachni.reports.run( @arachni.audit_store( true ) )
                end

                kill_interrupt_handler
                Thread.exit
            }

            mute!
            clear_screen!
            loop do

                print_line( restr, true )
                move_to_home!
                print_info( restr( 'Results thus far:' ), true )

                begin
                    print_issues( @arachni.audit_store( true ), true )
                    print_stats( true, true )
                rescue Exception => e
                    exception_jail{ raise e }
                    raise e
                end

                print_info( restr( 'Continue? (hit \'enter\' to continue, \'r\' to generate reports and \'e\' to exit)' ), true )
                flush!

                ::IO::select( nil, nil, nil, 0.3 )
            end

            unmute!
        }

    end

    # 
    # Handles SIGUSR1 system calls
    # 
    # It will cause Arachni to create a report and shut down afterwards
    # 
    def handle_usr1_interrupt
      print_status( 'Received SIGUSR1. Creating report and exiting...' )
      @arachni.reports.run( @arachni.audit_store( true ) )
      print_info( 'Please wait while the system cleans up.' )

      # kill the audit
      @audit.exit
      @exit_handler = Thread.new {
        @arachni.clean_up!( true )
        @arachni.reports.run( @arachni.audit_store( true ) )
        print_stats
      }
    end
    
    
    def print_issues( audit_store, unmute = false )

        print_line( restr, unmute )
        print_info( restr( audit_store.issues.size.to_s +
          ' issues have been detected.' ), unmute )

        print_line( restr, unmute )

        issues    = audit_store.issues
        issue_cnt = audit_store.issues.count
        issues.each.with_index {
            |issue, i|

            input = issue.var ? " input `#{issue.var}`" : ''
            meth  = issue.method ? " using #{issue.method}" : ''
            cnt   = "#{i + 1} |".rjust( issue_cnt.to_s.size + 2 )

            print_ok( restr(  "#{cnt} #{issue.name} at #{issue.url} in" +
                " #{issue.elem}#{input}#{meth}." ),
                unmute
            )
        }

        print_line( restr, unmute )
    end

    #
    # It parses and processes the user options.
    #
    # Loads modules, reports, saves/loads profiles etc.<br/>
    # It basically prepares the framework before calling {Arachni::Framework#run}.
    #
    def parse_opts(  )

        if !@opts.repload && !@opts.help

            if( !@opts.mods || @opts.mods.empty? )
                print_info( "No modules were specified." )
                print_info( " -> Will run all mods." )

                @opts.mods = ['*']
            end

            if( !@opts.audit_links &&
                !@opts.audit_forms &&
                !@opts.audit_cookies &&
                !@opts.audit_headers
              )
                print_info( "No audit options were specified." )
                print_info( " -> Will audit links, forms and cookies." )

                @opts.audit_links   = true
                @opts.audit_forms   = true
                @opts.audit_cookies = true
            end

        end

        @arachni.plugins.load_defaults!
        @opts.to_h.each {
            |opt, arg|

            case opt.to_s

                when 'help'
                    usage
                    exit 0

                when 'arachni_verbose'
                    verbose!

                when 'debug'
                    debug!

                when 'only_positives'
                    only_positives!

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
                    print_profile( )
                    exit 0

                when 'save_profile'
                    exception_jail{ save_profile( arg ) }
                    exit 0

                when 'mods'
                    begin
                        exception_jail{
                            @opts.mods = @arachni.modules.load( arg )
                        }
                    rescue
                        exit 0
                    end

                when 'reports'
                    begin
                        exception_jail{ @arachni.reports.load( arg.keys ) }
                    rescue
                        exit 0
                    end

                when 'plugins'
                    begin
                        exception_jail{ @arachni.plugins.load( arg.keys ) }
                    rescue
                        exit 0
                    end

                when 'repload'
                    exception_jail{ @arachni.reports.run( AuditStore.load( arg ), false ) }
                    exit 0

            end
        }

        # Check for missing url
        if( !@opts.url &&  !@opts.repload )
            print_error( "Missing url argument." )
            exit 0
        end

    end

    #
    # Outputs all available modules and their info.
    #
    def lsmod
        print_line
        print_line
        print_info( 'Available modules:' )
        print_line

        mods = @arachni.lsmod

        i = 0
        mods.each {
            |info|

            print_status( "#{info[:mod_name]}:" )
            print_line( "--------------------" )

            print_line( "Name:\t\t"       + info[:name] )
            print_line( "Description:\t"  + info[:description] )

            if( info[:elements] && info[:elements].size > 0 )
                print_line( "Elements:\t" +
                    info[:elements].join( ', ' ).downcase )
            end

            print_line( "Author:\t\t"     + info[:author].join( ", " ) )
            print_line( "Version:\t"      + info[:version] )

            if( info[:references] )
                print_line( "References:" )
                info[:references].keys.each {
                    |key|
                    print_info( key + "\t\t" + info[:references][key] )
                }
            end

            if info[:targets]
                print_line( "Targets:" )
                info[:targets].keys.each {
                    |key|
                    print_info( key + "\t\t" + info[:targets][key] )
                }
            end

            if( info[:issue] &&
                ( sploit = info[:issue][:metasploitable] ) )
                print_line( "Metasploitable:\t" + sploit )
            end

            print_line( "Path:\t"    + info[:path] )

            i+=1

            # pause every 3 modules to give the user time to read
            # (cheers to aungkhant@yehg.net for suggesting it)
            if( i % 3 == 0 && i != mods.size )
                print_line
                print_line( 'Hit <space> <enter> to continue, any other key to exit. ' )

                if gets[0] != " "
                    print_line
                    return
                end

            end

            print_line
        }

    end

    #
    # Outputs all available reports and their info.
    #
    def lsrep
        print_line
        print_line
        print_info( 'Available reports:' )
        print_line

        @arachni.lsrep().each {
            |info|

            print_status( "#{info[:rep_name]}:" )
            print_line( "--------------------" )

            print_line( "Name:\t\t"       + info[:name] )
            print_line( "Description:\t"  + info[:description] )

            if( info[:options] && !info[:options].empty? )
                print_line( "Options:\t" )

                info[:options].each {
                    |option|
                    print_info( "\t#{option.name} - #{option.desc}" )
                    print_info( "\tType:        #{option.type}" )
                    print_info( "\tDefault:     #{option.default}" )
                    print_info( "\tRequired?:   #{option.required?}" )

                    print_line( )
                }
            end

            print_line( "Author:\t\t"     + info[:author].join( ", " ) )
            print_line( "Version:\t"      + info[:version] )
            print_line( "Path:\t"         + info[:path] )

            print_line
        }

    end

    #
    # Outputs all available reports and their info.
    #
    def lsplug
        print_line
        print_line
        print_info( 'Available plugins:' )
        print_line

        @arachni.lsplug().each {
            |info|

            print_status( "#{info[:plug_name]}:" )
            print_line( "--------------------" )

            print_line( "Name:\t\t"       + info[:name] )
            print_line( "Description:\t"  + info[:description] )

            if( info[:options] && !info[:options].empty? )
                print_line( "Options:\t" )

                info[:options].each {
                    |option|
                    print_info( "\t#{option.name} - #{option.desc}" )
                    print_info( "\tType:        #{option.type}" )
                    print_info( "\tDefault:     #{option.default}" )
                    print_info( "\tRequired?:   #{option.required?}" )

                    print_line( )
                }
            end

            print_line( "Author:\t\t"     + info[:author].join( ", " ) )
            print_line( "Version:\t"      + info[:version] )
            print_line( "Path:\t"         + info[:path] )

            print_line
        }

    end


    #
    # Loads an Arachni Framework Profile file and merges it with the
    # user supplied options.
    #
    # @param    [String]    filename    the file to load
    #
    def load_profile( profiles )
        exception_jail{
            @opts.load_profile = nil
            profiles.each {
                |filename|
                @opts.merge!( @opts.load( filename ) )
            }
        }
    end

    #
    # Saves options to an Arachni Framework Profile file.<br/>
    # The file will be appended with the {PROFILE_EXT} extension.
    #
    # @param    [String]    filename
    #
    def save_profile( filename )

        if filename = @opts.save( filename )
            print_status( "Saved profile in '#{filename}'." )
            print_line( )
        else
            banner( )
            print_error( 'Could not save profile.' )
            exit 0
        end
    end

    def print_profile( )
        print_info( 'Running profile:' )
        print_info( @opts.to_args )
    end

    #
    # Outputs Arachni banner.<br/>
    # Displays version number, revision number, author details etc.
    #
    # @see VERSION
    # @see REVISION
    #
    # @return [void]
    #
    def banner

        print_line 'Arachni - Web Application Security Scanner Framework v' +
            @arachni.version + ' [' + @arachni.revision + ']
       Author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
                                      <zapotek@segfault.gr>
               (With the support of the community and the Arachni Team.)

       Website:       http://arachni.segfault.gr - http://github.com/Arachni/arachni
       Documentation: http://github.com/Arachni/arachni/wiki'
        print_line
        print_line

    end

    #
    # Outputs help/usage information.<br/>
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
    --help                      output this

    -v                          be verbose

    --debug                     show what is happening internally
                                  (You should give it a shot sometime ;) )

    --only-positives            echo positive results *only*

    --http-req-limit            concurrent HTTP requests limit
                                  (Be careful not to kill your server.)
                                  (Default: #{@opts.http_req_limit})
                                  (*NOTE*: If your scan seems unresponsive try lowering the limit.)

    --http-harvest-last         build up the HTTP request queue of the audit for the whole site
                                 and harvest the HTTP responses at the end of the crawl.
                                 (In some test cases this option has split the scan time in half.)
                                 (Default: responses will be harvested for each page)
                                 (*NOTE*: If you are scanning a high-end server and
                                   you are using a powerful machine with enough bandwidth
                                   *and* you feel dangerous you can use
                                   this flag with an increased '--http-req-limit'
                                   to get maximum performance out of your scan.)
                                 (*WARNING*: When scanning large websites with hundreds
                                  of pages this could eat up all your memory pretty quickly.)

    --cookie-jar=<cookiejar>    Netscape HTTP cookie file, use curl to create it


    --user-agent=<user agent>   specify user agent

    --custom-header='<name>=<value>'

                                specify custom headers to be included in the HTTP requests
                                (Can be used multiple times.)

    --authed-by=<who>           who authorized the scan, include name and e-mail address
                                  (It'll make it easier on the sys-admins during log reviews.)
                                  (Will be appended to the user-agent string.)


    Profiles -----------------------

    --save-profile=<file>       save the current run profile/options to <file>

    --load-profile=<file>       load a run profile from <file>
                                  (Can be used multiple times.)
                                  (You can complement it with more options, except for:
                                      * --mods
                                      * --redundant)

    --show-profile              will output the running profile as CLI arguments


    Crawler -----------------------

    -e <regex>
    --exclude=<regex>           exclude urls matching regex
                                  (Can be used multiple times.)

    -i <regex>
    --include=<regex>           include urls matching this regex only
                                  (Can be used multiple times.)

    --redundant=<regex>:<count> limit crawl on redundant pages like galleries or catalogs
                                  (URLs matching <regex> will be crawled <count> amount of times.)
                                  (Can be used multiple times.)

    -f
    --follow-subdomains         follow links to subdomains (default: off)

    --obey-robots-txt           obey robots.txt file (default: off)

    --depth=<number>            depth limit (default: inf)
                                  (How deep Arachni should go into the site structure.)

    --link-count=<number>       how many links to follow (default: inf)

    --redirect-limit=<number>   how many redirects to follow (default: #{@opts.redirect_limit})

    --extend-paths=<file>       add the paths in <file> to the ones discovered by the crawler
                                  (Can be used multiple times.)

    --restrict-paths=<file>     use the paths in <file> instead of crawling
                                  (Can be used multiple times.)


    Auditor ------------------------

    -g
    --audit-links               audit link variables (GET)

    -p
    --audit-forms               audit form variables
                                  (usually POST, can also be GET)

    -c
    --audit-cookies             audit cookies (COOKIE)

    --exclude-cookie=<name>     cookies not to audit
                                  (You should exclude session cookies.)
                                  (Can be used multiple times.)

    --audit-headers             audit HTTP headers
                                  (*NOTE*: Header audits use brute force.
                                   Almost all valid HTTP request headers will be audited
                                   even if there's no indication that the web app uses them.)
                                  (*WARNING*: Enabling this option will result in increased requests,
                                   maybe by an order of magnitude.)


    Modules ------------------------

    --lsmod=<regexp>            list available modules based on the provided regular expression
                                  (If no regexp is provided all modules will be listed.)
                                  (Can be used multiple times.)


    -m <modname,modname..>
    --mods=<modname,modname..>  comma separated list of modules to deploy
                                  (Use '*' as a module name to deploy all modules or inside module names like so:
                                      xss_*   to load all xss modules
                                      sqli_*  to load all sql injection modules
                                      etc.

                                   You can exclude modules by prefixing their name with a dash:
                                      --mods=*,-backup_files,-xss
                                   The above will load all modules except for the 'backup_files' and 'xss' modules.

                                   Or mix and match:
                                      -xss_*   to unload all xss modules. )


    Reports ------------------------

    --lsrep                       list available reports

    --repload=<file>              load audit results from an .afr file
                                    (Allows you to create new reports from finished scans.)

    --report='<report>:<optname>=<val>,<optname2>=<val2>,...'

                                  <report>: the name of the report as displayed by '--lsrep'
                                    (Default: stdout)
                                    (Can be used multiple times.)


    Plugins ------------------------

    --lsplug                      list available plugins

    --plugin='<plugin>:<optname>=<val>,<optname2>=<val2>,...'

                                  <plugin>: the name of the plugin as displayed by '--lsplug'
                                    (Can be used multiple times.)


    Proxy --------------------------

    --proxy=<server:port>         specify proxy

    --proxy-auth=<user:passwd>    specify proxy auth credentials

    --proxy-type=<type>           proxy type can be http, http_1_0, socks4, socks5, socks4a
                                    (Default: http)


USAGE
    end

end

end
end
