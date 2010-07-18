=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

require 'rubygems'
require $runtime_args['dir']['lib'] + 'ui/cli/output'
require $runtime_args['dir']['lib'] + 'spider'
require $runtime_args['dir']['lib'] + 'analyzer'
require $runtime_args['dir']['lib'] + 'vulnerability'
require $runtime_args['dir']['lib'] + 'module/http'
require $runtime_args['dir']['lib'] + 'module'
require $runtime_args['dir']['lib'] + 'module_registrar'
require $runtime_args['dir']['lib'] + 'module_registry'
require 'ap'
require 'pp'

module Arachni

module UI

class CLI

    attr_reader :opts

    include Arachni::UI::Output

    def initialize( opts )
        @opts = Hash.new
        
        @opts = @opts.merge( opts )
            
        banner
        
        @modreg = Arachni::ModuleRegistry.new( @opts['dir']['modules'] )

        parse_opts
        validate_opts

        @spider   = Arachni::Spider.new( @opts )
        @analyzer = Arachni::Analyzer.new( @opts )

    end

    def run( )
        print_status( 'Initing...' )

        ls_loaded
        analyze_site
        #    ap Arachni::ModuleRegistry.get_results
        print_results
    end

    private

    def print_results
        results = Arachni::ModuleRegistry.get_results
        if !results || results.size == 0
            print_status( 'No results were compiled by the modules.' )
        end

#        my_results = Hash.new
#        Arachni::ModuleRegistry.get_results.each {
#            |result|
#            result.keys.each {
#                |key|
#                
#                if( !my_results[key] )
#                    my_results[key] = Hash.new
#                end
#                
#                result[key].keys.each {
#                    |deep_key|
#
#                    if !result[key][deep_key] ||
#                        result[key][deep_key].size == 0 then next end
#
#                    if( !my_results[key][deep_key] )
#                        my_results[key][deep_key] = []
#                    end
#
#                    my_results[key][deep_key] << result[key][deep_key][0]
#                }
#            }
#        }

        ap results
    end

    def analyze_site
        print_status( 'Analysing site structure...' )
        print_status( '---------------------------' )
        print_line

        $_interrupted = false
        trap( "INT" ) { $_interrupted = true }
        skip_to_audit = false

        structure = site_structure = Hash.new
        mods_run_last_data = []

        sitemap = @spider.run {
            | url, html, headers |

#            if( @opts[:delay] )
#                sleep( @opts[:delay] )
#            end
            
            if $_interrupted == true
                print_line
                print_info( 'Exiting...' )
                exit 0
            end
            
            skip = false
            @opts[:redundant].each_with_index {
                |redundant, i|
                
                if( @opts[:redundant][i]['count'] == 0 )
                    skip = true
                    next
                end
                
                if( url =~ redundant['regexp'] )
                    
                    print_info( 'Matched redundancy rule: ' + 
                        redundant['regexp'].to_s + ' for page \'' +
                        url + '\'' )
                        
                    print_info( 'Count-down: ' +
                        @opts[:redundant][i]['count'].to_s )
                        
                    @opts[:redundant][i]['count'] -= 1
                end
            }
            
            if( skip == true )
                print_info( 'Page discarded...' )
                next
            end
            
            
            structure = site_structure[url] =
            @analyzer.run( url, html, headers ).clone

            page_data = {
                'url'        => { 'href' => url,
                'vars'       => @analyzer.get_link_vars( url )
                },
                'html'       => html,
                'headers'    => headers,
                'cookies' => @opts[:cookies]
            }

            if !@opts[:mods_run_last]
                run_mods( page_data, structure )
            else

                if $_interrupted == true
                    print_line
                    print_info( 'Site analysis was interrupted,' +
                    ' do you want to audit the analyzed pages?' )

                    print_info( 'Audit?(\'y\' to audit, \'n\' to exit)(y/n)' )

                    if gets[0] == 'y'
                        skip_to_audit = true
                    else
                        print_info( 'Exiting...' )
                        exit 0
                    end

                end
                
                mods_run_last_data.push( { page_data => structure} )
                    
            end

            if skip_to_audit == true
                print_info( 'Skipping to audit.' )
                print_line
                $_interrupted = false
                break
            end

        }

        if @opts[:mods_run_last]
            mods_run_last_data.each {
                |data|
                run_mods( data.keys[0], data.values[0] )
            }
        end

    end

    def ls_loaded
        print_line
        print_debug( 'ModuleRegistry reports the following modules as loaded:' )
        print_debug( '----------' )

        @modreg.ls_loaded( ).each {
            |mod|
            print_debug( mod )
        }

        print_line
    end

    
    def run_mods( page_data, structure )

        mod_queue = Queue.new
        
        threads = ( 1..@opts[:threads] ).map {
            |i|
            Thread.new( mod_queue ) {
                |q|
                until( q == ( curr_mod = q.deq ) )
                    print_debug( )
                    print_debug( 'Thread-' + i.to_s + " " + curr_mod.inspect )
                    print_debug( )
                    
                    if $_interrupted == true
                        print_line
                        print_info( 'Site audit was interrupted, exiting...' )
                        print_line
                        print_results( )
                        exit 0
                    end
                    
                    print_line
                    print_status( curr_mod.to_s )
                    print_status( '---------------------------' )
                    mod_new = curr_mod.new( page_data, structure )
                    
                    mod_new.prepare   if curr_mod.method_defined?( 'prepare' )
                    mod_new.run
                    mod_new.clean_up  if curr_mod.method_defined?( 'clean_up' )
                end
            }
        }
        
        # enque the loaded mods
        for mod in @modreg.ls_loaded
            mod_queue.enq mod
        end
        
        # send terminators down the queue
        threads.size.times { mod_queue.enq mod_queue }
        
        # wait for threads to finish
        threads.each { |t| t.join }
            
    end
    

    def parse_opts(  )

        @opts.each do |opt, arg|

            case opt.to_s

                when 'help'
                    usage
                    exit 0
                    
                when 'mods'
                    #
                    # Check the validity of user provided module names
                    #
                    @opts[:mods].each {
                        |mod_name|
                        
                        # if the mod name is '*' load all modules
                        if mod_name == '*'
                            print_info( 'Loading all modules...' )
                            @modreg.ls_available(  ).keys.each {
                                |mod|
                                @modreg.mod_load( mod )
                            }
                            break
                        end
                            
                        if( !@modreg.ls_available(  )[mod_name] )
                            print_error( "Error: Module #{mod_name} wasn't found." )
                            print_info( "Run arachni with the '-l' " + 
                                "parameter to see all available modules." )
                            exit 0
                        end
            
                        # load the module
                        @modreg.mod_load( mod_name )
            
                    }

                when 'arachni_verbose'
                    verbose!

                when 'debug'
                    debug!

                when 'only_positives'
                    only_positives!

                when 'cookie_jar'
                    @opts[:cookies] = HTTP.parse_cookiejar( @opts[:cookie_jar] )

                when 'lsmod'
                    lsmod
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

        @modreg.ls_available().each_pair {
            |mod_name, path|

            @modreg.mod_load( mod_name )

            print_status( "#{mod_name}:" )
            print_line( "--------------------" )

            info = @modreg.mod_info( i )

#            info = mod_info( reg_id )
            
            print_line( "Name:\t\t"       + info["Name"].strip )
            print_line( "Description:\t"  + info["Description"].strip )
            print_line( "HTTP Methods:\t" +
                info["Methods"].join( ', ' ).downcase )
            print_line( "Author:\t\t"     + info["Author"].strip )
            print_line( "Version:\t"      + info["Version"].strip )
                
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
            
            i+=1

            print_line
        }

    end

    def validate_opts

        # TODO: remove global vars
        if !@opts[:user_agent]
            @opts[:user_agent] = $runtime_args[:user_agent] =
                'Arachni/' + VERSION
        end
        
        if !@opts[:audit_links] &&
            !@opts[:audit_forms] &&
            !@opts[:audit_cookies]
            print_error( "Error: No audit options were specified." )
            print_info( "Run arachni with the '-h' parameter for help." )
            print_line
            exit 0
        end

        #
        # Ensure that the user selected some modules
        #
        if !@opts[:mods]
            print_error( "Error: No modules were specified." )
            print_info( "Run arachni with the '-h' parameter for help or " )
            print_info( "with the '-l' parameter to see all available modules." )
            print_line
            exit 0
        end

        # Check for missing url
        if @opts[:url] == nil
            print_error( "Error: Missing url argument (try --help)" )
            print_line
            exit 0
        end

        #
        # Try and parse URL.
        # If it fails inform the user of that fact and
        # give him some approriate examples.
        #
        begin
            require 'uri'
            @opts[:url] = URI.parse( URI.encode( @opts[:url] ) )
        rescue
            print_error( "Error: Invalid or missing URL argument." )
            
            print_info( "URL must be of type 'scheme://username:passw' + 
                'ord@subdomain.domain.tld:port/path?query_string#anchor'" )
            
            print_info( "Be careful with the \"www\"." )
            print_line
            print_info( "Examples:" )
            print_info( "    http://www.google.com" )
            print_info( "    https://secure.wikimedia.org/wikipedia/en/wiki/Main_Page" )
            print_info( "    http://zapotek:secret@www.myweb.com/index.php" )
            print_line
            exit 0
        end

#        #
#        # If proxy type is socks include socksify
#        # and let it proxy all tcp connections for us.
#        #
#        # Then nil out the proxy opts or else they're going to be
#        # passed as an http proxy to Anemone::HTTP.refresh_connection()
#        #
#        if @opts[:proxy_type] == 'socks'
#            require 'socksify'
#
#            TCPSocket.socks_server = @opts[:proxy_addr]
#            TCPSocket.socks_port = @opts[:proxy_port]
#
#            @opts[:proxy_addr] = nil
#            @opts[:proxy_port] = nil
#        end

        #
        # If proxy type is socks include socksify
        # and let it proxy all tcp connections for us.
        #
        # Then nil out the proxy opts or else they're going to be
        # passed as an http proxy to Anemone::HTTP.refresh_connection()
        #
        if !@opts[:threads]
            print_info( 'No thread limit specified, defaulting to 3.' )
            @opts[:threads] = 3
        end
        
        # make sure the provided cookie-jar file exists
        if @opts[:cookie_jar] && !File.exist?( @opts[:cookie_jar] )
            print_error( 'Error: Cookie-jar \'' + @opts[:cookie_jar] +
                        '\' doesn\'t exist.' )
            exit 0
        end
        
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

        print_line 'Arachni v' + VERSION + ' [' + REVISION + '] initiated.
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
                                                                      
    -l
    --lsmod                     list available modules
  
      
    -m <modname,modname..>
    --mods=<modname,modname..>  comma separated list of modules to deploy
                                  (use '*' to deploy all modules)
    
    --mods-run-last             run modules after the website has been analyzed
                                  (default: modules are run on every page
                                    encountered to minimize network latency.) 
    
  
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
