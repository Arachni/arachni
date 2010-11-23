=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end


module Arachni

require Options.instance.dir['lib'] + 'ui/cli/output'
require Options.instance.dir['lib'] + 'framework'

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
# @version: 0.1.6
# @see Arachni::Framework
#
class CLI

    #
    # Instance options
    #
    # @return    [Options]
    #
    attr_reader :opts

    #
    # The extension of the profile files.
    #
    # @return    [String]
    #
    PROFILE_EXT = '.afp'

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

        exception_jail {
            # work on the user supplied arguments
            parse_opts( )
        }

        # trap Ctrl+C interrupts
        trap( 'INT' ) { handle_interrupt( ) }

    end

    #
    # Runs Arachni
    #
    def run( )

        print_status( 'Initing...' )

        begin
            # start the show!
            @arachni.run( )
            print_stats
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

    def print_stats
        stats   = @arachni.stats

        print_line
        print_info( "Sent #{stats[:requests]} requests." )
        print_info( "Received and analyzed #{stats[:responses]} responses." )
        print_info( 'In ' + stats[:time] )

        avg = 'Average: ' + stats[:avg] + ' requests/second.'
        print_info( avg )

        print_line

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
    def handle_interrupt( )

        print_line
        print_info( 'Results thus far:' )

        begin
            print_vulns( @arachni.audit_store( true ) )
        rescue Exception => e
            exception_jail{ raise e }
            exit 0
        end

        print_info( 'Arachni was interrupted,' +
            ' do you want to continue?' )

        print_info( 'Continue? (hit \'enter\' to continue, \'e\' to exit)' )

        if gets[0] == 'e'
            print_info( 'Exiting...' )
            exit 0
        end

    end

    def print_vulns( audit_store )

        print_line( )
        print_info( audit_store.vulns.size.to_s +
          ' vulnerabilities were detected.' )

        print_line( )
        audit_store.vulns.each {
            |vuln|

            print_ok( "#{vuln.name} (In #{vuln.elem} variable '#{vuln.var}'" +
              " - Severity: #{vuln.severity} - Variations: #{vuln.variations.size.to_s})" )

            print_info( vuln.variations[0]['url'] )

            print_line( )
        }

        print_line( )

    end

    #
    # It parses and processes the user options.
    #
    # Loads modules, reports, saves/loads profiles etc.<br/>
    # It basically prepares the framework before calling {Arachni::Framework#run}.
    #
    def parse_opts(  )

        if !@opts.repload

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
                    begin
                        exception_jail{ @arachni.reports.run( AuditStore.load( arg ) ) }
                    rescue
                        exit 0
                    end

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

        mods = @arachni.lsmod( )

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

            print_line( "Author:\t\t"     + info[:author] )
            print_line( "Version:\t"      + info[:version] )

            if( info[:references] )
                print_line( "References:" )
                info[:references].keys.each {
                    |key|
                    print_info( key + "\t\t" + info[:references][key] )
                }
            end

            print_line( "Targets:" )
            info[:targets].keys.each {
                |key|
                print_info( key + "\t\t" + info[:targets][key] )
            }

            if( info[:vulnerability] &&
                ( sploit = info[:vulnerability][:metasploitable] ) )
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
                    print_info( "\tType:    #{option.type}" )
                    print_info( "\tDefault: #{option.default}" )

                    print_line( )
                }
            end

            print_line( "Author:\t\t"     + info[:author] )
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
                    print_info( "\tType:    #{option.type}" )
                    print_info( "\tDefault: #{option.default}" )

                    print_line( )
                }
            end

            print_line( "Author:\t\t"     + info[:author] )
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
                @opts.merge!( YAML::load( IO.read( filename ) ) )
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
        profile = @opts

        profile.dir          = nil
        profile.load_profile = nil
        profile.save_profile = nil
        profile.authed_by    = nil

        begin
            f = File.open( filename + PROFILE_EXT, 'w' )
            YAML.dump( profile, f )
            print_status( "Saved profile in '#{f.path}'." )
            print_line( )
        rescue Exception => e
            banner( )
            exception_jail{ raise e }
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

       Website:       http://github.com/Zapotek/arachni
       Documentation: http://github.com/Zapotek/arachni/wiki'
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

    --http-req-limit            concurent HTTP requests limit
                                  (Be carefull not to kill your server.)
                                  (Default: 60)
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
                                 (*WARNING*: When scanning large websites with hundreads
                                  of pages this could eat up all your memory pretty quickly.)

    --cookie-jar=<cookiejar>    netscape HTTP cookie file, use curl to create it


    --user-agent=<user agent>   specify user agent

    --authed-by=<who>           who authorized the scan, include name and e-mail address
                                  (It'll make it easier on the sys-admins during log reviews.)
                                  (Will be appended to the user-agent string.)


    Profiles -----------------------

    --save-profile=<file>       save the current run profile/options to <file>
                                  (The file will be saved with an extention of: #{PROFILE_EXT})

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
                                  (URLs matching <regex> will be crawled <count> links deep.)
                                  (Can be used multiple times.)

    -f
    --follow-subdomains         follow links to subdomains (default: off)

    --obey-robots-txt           obey robots.txt file (default: off)

    --depth=<number>            depth limit (default: inf)
                                  (How deep Arachni should go into the site structure.)

    --link-count=<number>       how many links to follow (default: inf)

    --redirect-limit=<number>   how many redirects to follow (default: inf)


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
                                  (Use '*' to deploy all modules)
                                  (You can exclude modules by prefixing their name with a dash:
                                      --mods=*,-backup_files,-xss
                                   The above will load all modules except for the 'backup_files' and 'xss' modules. )


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
