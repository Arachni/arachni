=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

require $runtime_args['dir']['lib'] + 'framework'
    
module Arachni

module UI

#
# Arachni::UI:CLI class<br/>
# Provides a command line interface for the Arachni Framework.
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: 0.1-planning
#
class CLI

    #
    # Instance options
    #
    # @return    [Hash]
    #
    attr_reader :opts

    # the output interface for CLI
    include Arachni::UI::Output

    #
    # Initializes the command line interface and the framework
    #
    # @param    [Hash]    options
    #
    def initialize( opts )
        
        ap @opts = opts
        
        if !@opts[:reports]
            @opts[:reports] = []
            @opts[:reports][0] = { 'stdout' => nil }
        end
        
        @arachni = Arachni::Framework.new( opts )
        
        banner( )
        
        parse_opts( )
    end

    #
    # Runs Arachni
    #
    def run( )
        
        print_status( 'Initing...' )
                
        begin
            ls_loaded( )
            @arachni.run( )
        rescue Arachni::Exceptions::NoMods => e
            print_error( e.to_s )
            print_info( "Run arachni with the '-h' parameter for help or " )
            print_info( "with the '-l' parameter to see all available modules." )
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
            e.backtrace.each{ |line| print_debug( line ) }
            print_line
            exit 0
        end
        
        print_results( )
    end

    private

    def print_results
        results = @arachni.get_results( )
        if !results || results.size == 0
            print_status( 'No results were compiled by the modules.' )
        end
    end

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

    
    def parse_opts(  )

        @opts.each do |opt, arg|

            case opt.to_s

                when 'help'
                    usage
                    exit 0
                    
                when 'mods'
                    begin
                        @arachni.mod_load( @opts[:mods] )
                    rescue Arachni::Exceptions::DepModNotFound => e
                        print_error( e.to_s )
                        print_line
                        exit 0
                    end

                when 'reports'
                    begin
                        @arachni.rep_load( @opts[:reports].keys )
                    rescue Arachni::Exceptions::ReportNotFound => e
                        print_error( e.to_s )
                        print_line
                        exit 0
                    end
                                        
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
                                        
#                when 'delay'
#                    @opts[:delay] = Float.new( @opts[:delay] ) 

            end
        end

    end

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
            print_line( "HTTP Methods:\t" +
                info["Methods"].join( ', ' ).downcase )
            
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
            print_line( "Author:\t\t"     + info["Author"] )
            print_line( "Version:\t"      + info["Version"] )
            print_line( "Path:\t"         + info['Path'] )

            i+=1

            print_line
        }

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
       Author: Anastasios "Zapotek" Laskos <zapotek@segfault.gr>
                                           <tasos.laskos@gmail.com>
       Website: http://www.segfault.gr'
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
    
    -r
    --resume                    resume suspended session
    
    -v                          be verbose

USAGE
#    --delay                     how long to wait between HTTP requests
#                                  Time is set in seconds, you can use floating point.

        print_line <<USAGE 
    --debug                     show debugging output
    
    --only-positives            echo positive results *only*
  
    --threads=<number>          how many threads to instantiate (default: 3)
                                  More threads does not necessarily mean more speed,
                                  be careful when adjusting the thread count.
                                  
    --cookie-jar=<cookiejar>    netscape HTTP cookie file, use curl to create it
                                  Cookies in this file will not be audited,
                                  so remove any cookies that you do want to audit.
                                
    
    --user-agent=<user agent>   specify user agent
    
    
    Crawler -----------------------
    
    -e <regex>
    --exclude=<regex>           exclude urls matching regex
                                  You can use it multiple times.
    
    -i <regex>
    --include=<regex>           include urls matching this regex only

    --redundant=<regex>:<count> limit crawl on redundant pages like galleries or catalogs
                                  (URLs matching <regex> will be crawled <count> links deep.)
                                  (Can be used multiple times.)
    
    -f
    --follow-subdomains         follow links to subdomains (default: off)
    
    --obey-robots-txt           obey robots.txt file (default: false)
    
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
    
    
    --report=<repname>:<outfile>  <repname>: the name of the report as displayed by '--lsrep'
                                  <outfile>: where to save the report
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
