=begin
                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

    
module Arachni

require Options.instance.dir['lib'] + 'framework'
        
module UI

#
# Arachni::UI:CLI class
#
# Provides a command line interface for the Arachni Framework.<br/>
# Most of the logic is in the Framework class however profiles can only<br/>
# be loaded and saved at this level.    
#
# @author: Anastasios "Zapotek" Laskos 
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
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
    PROFILE_EXT     = '.afp'
    
    # the output interface for CLI
    include Arachni::UI::Output

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
        if( @opts.reports.size == 0 && !@opts.lsrep )
            @opts.reports << 'stdout'
        end
        
        # instantiate the big-boy!
        @arachni = Arachni::Framework.new( @opts  )
        
        # echo the banner
        banner( )
        
        # work on the user supplied arguments
        parse_opts( )
    end

    #
    # Runs Arachni
    #
    def run( )
        
        print_status( 'Initing...' )
                
        begin
            
            # this will output only if debug mode is on
            ls_loaded( )
            
            # start the show!
            @arachni.run( )
            
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
            print_error( e.inspect )
            print_debug( 'Backtrace:' )
            print_debug_backtrace( e )
            print_line
            exit 0
        end
    end

    private

    #
    # Outputs a list of the loaded modules using print_debug()<br/>
    # The list will only be echoed if debug mode is on. 
    #
    #
    def ls_loaded
        print_line
        print_debug( 'ModuleRegistry reports the following modules as loaded:' )
        print_debug( '----------' )

        @arachni.ls_loaded_mods( ).each {
            |mod|
            print_debug( mod )
        }

        print_line
    end

    #
    # It parses and processes the user options.
    #
    # Loads modules, reports, saves/loads profiles etc.<br/>
    # It basically prepares the framework before calling {Arachni::Framework#run}.
    #
    def parse_opts(  )

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
                    lsmod
                    exit 0
                
                when 'lsrep'
                    lsrep
                    exit 0

                when 'save_profile'
                    begin
                        save_profile( arg )
                    rescue Exceptions => e
                        handle_exception( e )
                    end                    
                    
                when 'mods'
                    begin
                        @arachni.mod_load( arg )
                    rescue Arachni::Exceptions::ModNotFound => e
                        print_error( e.to_s )
                        print_info( "Run arachni with the '-l' parameter" +
                            " to see all available modules." )
                        print_line
                        exit 0
                    rescue Exception => e
                        handle_exception( e )
                    end

                when 'reports'
                    begin
                        @arachni.rep_load( arg )
                    rescue Exception => e
                        handle_exception( e )
                    end
                    
                when 'repload'
                    begin
                        @arachni.rep_convert( arg )
                    rescue Exception => e
                        handle_exception( e )
                    end                    
                                        
#                when 'delay'
#                    @opts.delay = Float.new( arg ) 

            end
        }

    end

    #
    # Outputs all available modules and their info.
    #
    def lsmod
        i = 0
        print_info( 'Available modules:' )
        print_line

        @arachni.lsmod().each {
            |info|
            
            print_status( "#{info['mod_name']}:" )
            print_line( "--------------------" )

            print_line( "Name:\t\t"       + info["Name"] )
            print_line( "Description:\t"  + info["Description"] )
            
            if( info["Elements"] && info["Elements"].size > 0 )
            print_line( "HTML Elements:\t" +
                info["Elements"].join( ', ' ).downcase )
            end
            
            if( info["Dependencies"] )
                print_line( "Dependencies:\t" +
                    info["Dependencies"].join( ', ' ).downcase )
            end
            
            print_line( "Author:\t\t"     + info["Author"] )
            print_line( "Version:\t"      + info["Version"] )
                
            print_line( "References:" )
            info["References"].keys.each {
                |key|
                print_info( key + "\t\t" + info["References"][key] )
            }
            
            print_line( "Targets:" )
            info["Targets"].keys.each {
                |key|
                print_info( key + "\t\t" + info["Targets"][key] )
            }
            
            print_line( "Path:\t"    + info['Path'] )

            i+=1

            print_line
        }

    end

    #
    # Outputs all available reports and their info.
    #
    def lsrep
        i = 0
        print_info( 'Available reports:' )
        print_line

        @arachni.lsrep().each {
            |info|
            
            print_status( "#{info['rep_name']}:" )
            print_line( "--------------------" )

            print_line( "Name:\t\t"       + info["Name"] )
            print_line( "Description:\t"  + info["Description"] )
                
            if( info["Options"] && info["Options"].size > 0 )
                print_line( "Options:\t" )
                
                info["Options"].each_pair {
                    |option, info|
                    print_info( "\t#{option} - #{info[1]}" )
                    print_info( "\tValues: #{info[0]}" )
                    
                    print_line( )
                }    
            end
            
            print_line( "Author:\t\t"     + info["Author"] )
            print_line( "Version:\t"      + info["Version"] )
            print_line( "Path:\t"         + info['Path'] )

            i+=1

            print_line
        }

    end
    
    #
    # Loads an Arachni Framework Profile file and merges it with the
    # user supplied options.
    #
    # @param    [String]    filename    the file to load
    #
    def load_profile( filename )
        begin
            
            @opts.load_profile = nil
            @opts.merge!( YAML::load( IO.read( filename ) ) )
        rescue Exception => e
            print_error( e.to_s )
            print_debug_backtrace( e )
            print_line( )
            exit 0
        end
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
        rescue Exception => e
            banner( )
            print_error( e.to_s )
            print_debug_backtrace( e )
            print_line( )
            exit 0
        end

    end
    
    def handle_exception( e )
        print_error( e.to_s )
        print_debug_backtrace( e )
        print_line
        exit 0
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

        print_line 'Arachni v' + @arachni.version + ' [' +
            @arachni.revision + '] initiated.
       Authors: Anastasios "Zapotek" Laskos <zapotek@segfault.gr>
                                           <tasos.laskos@gmail.com>
                (With the support of the Arachni Team)
                
       Website: http://github.com/Zapotek/arachni'
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

USAGE
#    --delay                     how long to wait between HTTP requests
#                                  Time is set in seconds, you can use floating point.

        print_line <<USAGE 
    --debug                     show debugging output
    
    --only-positives            echo positive results *only*
  
    --threads=<number>          how many threads to instantiate
                                  If no thread limit has been specified
                                    each module will run in its own thread.
                                  
    --cookie-jar=<cookiejar>    netscape HTTP cookie file, use curl to create it
                                                                 
    
    --user-agent=<user agent>   specify user agent
    
    --authed-by=<who>           who authorized the scan, include name and e-mail address
                                  It'll make it easier on the sys-admins.
                                  (Will be appended to the user-agent string.)
    
    --save-profile=<file>       saves the current run profile/options to <file>
                                  (The file will be saved with an extention of: #{PROFILE_EXT})
                                  
    --load-profile=<file>       loads a run profile from <file>
                                  (You can complement it with more options, except for:
                                      * --mods
                                      * --redundant)
                                  
    
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
                                  How deep Arachni should go into the site structure.
                                  
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
                                  You should exclude session cookies.
                                  (Can be used multiple times.)
    
    --audit-headers             audit HTTP headers
                                  
                                  
    Modules ------------------------
                                                                      
    --lsmod                     list available modules
  
      
    -m <modname,modname..>
    --mods=<modname,modname..>  comma separated list of modules to deploy
                                  (use '*' to deploy all modules)
    
    --mods-run-last             run modules after the website has been analyzed
                                  (default: modules are run on every page
                                    encountered to minimize network latency.) 


    Reports ------------------------
    
    --lsrep                       list available reports
    
    --repsave=<file>              saves the audit results in <file>
                                    (The file will be saved with an extention of: #{@arachni.report_ext})               
    
    --repload=<file>              loads audit results from <file>
                                  and lets you create a new report
    
    --repopts=<option1>:<value>,<option2>:<value>,...
                                  Set options for the selected reports.
                                  (One invocation only, options will be applied to all loaded reports.)
                                  
    --report=<repname>          <repname>: the name of the report as displayed by '--lsrep'
                                  (default: stdout)
                                  (Can be used multiple times.)
                                  
                                  
    Proxy --------------------------
    
    --proxy=<server:port>       specify proxy
    
    --proxy-auth=<user:passwd>  specify proxy auth credentials
    
    --proxy-type=<type>         proxy type can be either socks or http
                                  (default: http)
    
  
USAGE

    end

end

end
end
