=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end


require 'rubygems'
require $runtime_args['dir']['lib'] + 'exceptions'
require $runtime_args['dir']['lib'] + 'ui/cli/output'
require $runtime_args['dir']['lib'] + 'spider'
require $runtime_args['dir']['lib'] + 'analyzer'
require $runtime_args['dir']['lib'] + 'page'
require $runtime_args['dir']['lib'] + 'audit_store'
require $runtime_args['dir']['lib'] + 'vulnerability'
require $runtime_args['dir']['lib'] + 'module/http'
require $runtime_args['dir']['lib'] + 'module/base'
require $runtime_args['dir']['lib'] + 'module/registrar'
require $runtime_args['dir']['lib'] + 'module/registry'
require $runtime_args['dir']['lib'] + 'report/base'
require $runtime_args['dir']['lib'] + 'report/registry'
require $runtime_args['dir']['lib'] + 'report/registrar'
require 'yaml'
require 'ap'
require 'pp'


module Arachni

#
# Arachni::Framework class
#    
# The Framework class ties together all the components.<br/>
# It should be wrapped by a UI class.
#
# It's the brains of the operation, it bosses the rest of the classes around.<br/>
# It runs the audit, loads modules and reports and runs them according to
# the supplied options.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1-pre
#
class Framework

    #
    # include the output interface but try to use it as little as possible
    #
    # the UI classes should take care of communicating with the user
    #
    include Arachni::UI::Output
    
    VERSION      = '0.1-pre'
    REVISION     = '$Rev$'
    REPORT_EXT   = '.afr'

    #
    # Instance options
    #
    # @return [Hash]
    #
    attr_reader :opts

    #
    # Initializes all the system components.
    #
    # @param    [Hash]    system opts
    #
    def initialize( opts )
        @opts = Hash.new
        
        @opts = @opts.merge( opts )
            
        @modreg = Arachni::Module::Registry.new( @opts['dir']['modules'] )
        @repreg = Arachni::Report::Registry.new( @opts['dir']['reports'] )
        
        parse_opts( )
        prepare_user_agent( )
        
        @spider   = Arachni::Spider.new( @opts )
        @analyzer = Arachni::Analyzer.new( @opts )
        
        # trap Ctrl+C interrupts
        $_interrupted = false
        trap( 'INT' ) { $_interrupted = true }
        
        # deep copy the redundancy rules to preserve their counter
        # for the reports
        @orig_redundant = deep_clone( @opts[:redundant] )
    end

    #
    # Runs the system
    #
    # It parses the instanse options and runs the audit
    #
    def run
        
        # pass all exceptions to the UI
        begin
            validate_opts
        rescue
            raise
        end
        
        @opts[:start_datetime] = Time.now
            
        # start the audit
        audit( )
        
        @opts[:finish_datetime] = Time.now
        @opts[:delta_time] = @opts[:finish_datetime] - @opts[:start_datetime]
        
        # run reports
        if( @opts[:reports] )
            begin
                run_reps( audit_store_get( ) )
            rescue Exception => e
                print_error( e.to_s )
                print_debug_backtrace( e )
                print_line
                exit 0
            end
        end
        
        # save the AuditStore in a file 
        if( @opts[:repsave] && !@opts[:repload] )
            begin
                audit_store_save( @opts[:repsave] )
            rescue Exception => e
                print_error( e.to_s )
                print_debug_backtrace( e )
                print_line
                exit 0
            end
        end
        
    end
    
    #
    # Audits the site.
    #
    # Runs the spider, analyzes each page and runs the loaded modules.
    #
    def audit
        pages = []
            
        # initiates the crawl
        sitemap = @spider.run {
            | url, html, headers |

            page = analyze( url, html, headers )
            
            # if the user wants to run the modules against each page
            # the crawler finds do it now...
            if( !@opts[:mods_run_last] )
                run_mods( page )
            else
                # ..else handle any interrupts that may occur... 
                handle_interrupt( )
                # ... and save the page data for later.
                pages << page
            end

        }

        # if the user opted to run the modules after the crawl/analysis
        # do it now.
        pages.each { |page| run_mods( page ) } if( @opts[:mods_run_last] )
            
    end

    #
    # Analyzes the html code for elements and returns a page object
    #
    # @param  [String]    url
    # @param  [String]    html
    # @param  [Array]     headers
    #
    # @return    [Page]
    #
    def analyze( url, html, headers )
        
        elements = Hash.new
        
        # analyze each page the crawler returns and save its elements
        elements = @analyzer.run( url, html, headers ).clone
    
        # if the user wants to audit the cookiejar cookies
        # append them to the page elements
        if( audit_cookiejar?( ) )
            elements['cookies'] =
                merge_with_cookiejar( elements['cookies'] )
        end
    
        # get the variables of the url query as an array of hashes
        query_vars = @analyzer.get_link_vars( url )
        
        # if url query has variables in it append them to the page elements
        if( query_vars.size > 0 )
            elements['links'] << {
                'href'  => url,
                'vars'  => query_vars
            }
        end
        
        if( elements['headers'] )
            request_headers = elements['headers'].clone
#            elements.delete( 'headers' )
        end
        
        return Page.new( {
            :url         => url,
            :query_vars  => query_vars,
            :html        => html,
            :headers     => headers,
            :request_headers => request_headers,
            :elements    => elements,
            :cookiejar   => @opts[:cookies]
        } )

    end
    
    #
    # Returns the results of the audit as an {AuditStore} instance
    #
    # @see AuditStore
    #
    # @return    [AuditStore]
    #
    def audit_store_get
        
        # restore the original redundacy rules and their counters
        @opts[:redundant] = @orig_redundant
        
         return AuditStore.new( {
            :version  => VERSION,
            :revision => REVISION,
            :options  => @opts,
            :vulns    => Arachni::Module::Registry.get_results( )
         } )
    end
    
    #
    # Returns an array of all loaded modules
    #
    # @return    [Array<Class>]
    #
    def ls_loaded_mods
        @modreg.ls_loaded( )
    end
    
    #
    # Returns an array of all loaded reports
    #
    # @return    [Array<Class>]
    #
    def ls_loaded_reps
        @repreg.ls_loaded( )
    end
    
    #
    # Loads modules
    #
    # @param [Array]  mods  Array of modules to load
    #
    def mod_load( mods = '*' )
        #
        # Check the validity of user provided module names
        #
        mods.each {
            |mod_name|
            
            # if the mod name is '*' load all modules
            # and replace it with the actual module names
            if( mod_name == '*' )
                
                @opts['mods'] = []
                
                @modreg.ls_available(  ).keys.each {
                    |mod|
                    @opts['mods'] << mod
                    @modreg.mod_load( mod )
                }
                
                # and we're done..
                break
            end
            
            # make sure the module name is valid...
            if( !@modreg.ls_available(  )[mod_name] )
                raise( Arachni::Exceptions::ModNotFound,
                    "Error: Module #{mod_name} wasn't found." )
            end

            # ...and load the module passing all exceptions to the UI.
            begin
                @modreg.mod_load( mod_name )
            rescue Exception => e
                raise e
            end
        }
    end

    #
    # Loads reports
    #
    # @param [Array]  reports  Array of reports to load
    #
    def rep_load( reports = ['stdout'] )

        reports.each {
            |report|
            
            if( !@repreg.ls_available(  )[report] )
                raise( Arachni::Exceptions::ReportNotFound,
                    "Error: Report #{report} wasn't found." )
            end
    
            begin
                # load the report
                @repreg.rep_load( report )
            rescue Exception => e
                raise e
            end
        }
    end

    #
    # Converts a saved AuditStore to a report.
    #
    # It basically loads a serialized AuditStore,<br/>
    # passes it to a the loaded Reports and runs the reports.
    #
    # @param [String]  file  location of the saved AuditStore
    #
    def rep_convert( file )
        run_reps( audit_store_load( file ) )
        exit 0
    end

    #
    # Saves an AuditStore instance in file
    #
    # @param    [String]    file
    #
    def audit_store_save( file )
        
        file += REPORT_EXT
        
        print_line( )
        print_status( 'Dumping audit results in \'' + file  + '\'.' )
        
        audit_store_get( ).save( file )
        
        print_status( 'Done!' )
    end
            
    #
    # Loads an {AuditStore} object
    #
    # @see AuditStore
    #
    # @param [String]  file  location of the dump file
    #
    def audit_store_load( file )
        return AuditStore.load( file )
    end
    
    #
    # Returns an array of hashes with information
    # about all available modules
    #
    # @return    [Array<Hash>]
    #
    def lsmod
        
        i = 0
        mod_info = []
        
        @modreg.ls_available().each_pair {
            |mod_name, path|
    
            @modreg.mod_load( mod_name )
    
            info = @modreg.mod_info( i )
    
            info["mod_name"]    = mod_name
            info["Name"]        = info["Name"].strip
            info["Description"] = info["Description"].strip
            
            if( !info["Dependencies"] )
                info["Dependencies"] = []
            end
            
            info["Author"]    = info["Author"].strip
            info["Version"]   = info["Version"].strip 
            info["Path"]      = path['path'].strip
            
            i+=1
            
            mod_info << info
        }
        
        # clean the registry inloading all modules
        Arachni::Module::Registry.clean( )
        
        return mod_info
    
    end
    
    #
    # Returns an array of hashes with information
    # about all available reports
    #
    # @return    [Array<Hash>]
    #
    def lsrep
        
        i = 0
        rep_info = []
        
        @repreg.ls_available( ).each_pair {
            |rep_name, path|
    
            @repreg.rep_load( rep_name )

            info = @repreg.info( i )

            info["rep_name"]    = rep_name
            info["Path"]        = path['path'].strip
            
            i+=1
            
            rep_info << info
        }
        return rep_info
    end
    
    #
    # Returns the version of the framework
    #
    # @return    [String]
    #
    def version
        VERSION
    end

    #
    # Returns the SVN revision of the framework
    #
    # @return    [String]
    #
    def revision
        REVISION
    end
    
    #
    # Returns the extension of the report files
    #
    # @return    [String]
    #
    def report_ext
        REPORT_EXT
    end
    
    private
    
    #
    # Merges 'cookies' with the cookiejar and returns it as an array
    #
    # @param    [Array<Hash>]  cookies
    #
    # @return   [Array<Hash>]  the merged cookies
    #
    def merge_with_cookiejar( cookies )
        @opts[:cookies].each_pair {
            |name, value|
            cookies << {
                'name'    => name,
                'value'   => value
            }
        }
        return cookies
    end
    
    #
    # Should we audit the cookiejar?
    #
    def audit_cookiejar?( )
        @opts[:audit_cookie_jar] && @opts[:cookies]
    end
    
    #
    # Prepares the user agent to be used throughout the system.
    #
    def prepare_user_agent
        # TODO: remove global vars
        if !@opts[:user_agent]
            @opts[:user_agent] = $runtime_args[:user_agent] =
                'Arachni/' + VERSION
        end
        
        # TODO: remove global vars
        if @opts[:authed_by]
            authed_by = " (Scan authorized by: #{@opts[:authed_by]})" 
            @opts[:user_agent]         += authed_by 
            $runtime_args[:user_agent] += authed_by
        end

    end
    
    #
    # It handles Ctrl+C interrupts
    #
    # Once an interrupt has been trapped the system pauses and waits
    # for user input. <br/>
    # The user can either continue or exit.
    #
    #
    def handle_interrupt( )
        
        if( $_interrupted == false ) then return false end
        
        print_line
        print_error( 'Arachni was interrupted,' +
            ' do you want to continue?' )
            
        print_error( 'Continue? (hit \'enter\' to continue, \'e\' to exit)' )
            
        if gets[0] == 'e'
            print_error( 'Exiting...' )
            exit 0
        end
        
        $_interrupted = false

    end
    
    #
    # Takes care of module execution and threading
    #
    # @see Page
    #
    # @param    [Page]    page
    #
    def run_mods( page )

        # create a queue that'll hold the modules to run
        mod_queue = Queue.new
        
        # start a new thread for every module in the queue
        # while obeying the thread-count limit. 
        @threads = ( 1..@opts[:threads] ).map {
            |i|
            
            # create a new thread...
            Thread.new( mod_queue ) {
                |q|
                # get a module from the queue until all queue items have been
                # consumed
                until( q == ( curr_mod = q.deq ) )
                    
                    # save some time by deciding if the module is worth running
                    if( !run_module?( curr_mod , page ) )
                        print_verbose( 'Skipping ' + curr_mod.to_s +
                            ', nothing to audit.' )
                        next
                    end

                    print_debug( )
                    print_debug( 'Thread-' + i.to_s + " " + curr_mod.inspect )
                    print_debug( )
                    
                    # tell the user which module is about to be run...
                    print_status( curr_mod.to_s )
                    # ... and run it.
                    run_mod( curr_mod, deep_clone( page ) )
                    
                    while( handle_interrupt(  ) )
                    end
                     
                end
            }
        }
        
        # enque the loaded mods
        for mod in ls_loaded_mods
            mod_queue.enq mod
        end
        
        # send terminators down the queue
        @threads.size.times { mod_queue.enq mod_queue }
        
        # wait for threads to finish
        @threads.each { |t| t.join }
            
    end
    
    #
    # Runs a module and passes it the page_data and structure.<br/>
    # It also handles any exceptions thrown by the module at runtime.
    #
    # @see Page
    #
    # @param    [Class]   mod      the module to run 
    # @param    [Page]    page
    #
    def run_mod( mod, page )
        begin
            # instantiate the module
            mod_new = mod.new( page )
            
            # run the methods specified in the module API
            
            # optional
            mod_new.prepare   if mod.method_defined?( 'prepare' )
            
            # mandatory
            mod_new.run
            
            # optional
            mod_new.clean_up  if mod.method_defined?( 'clean_up' )
        rescue Exception => e
            print_error( 'Error in ' + mod.to_s + ': ' + e.to_s )
            print_debug_backtrace( e )
        end
    end
    
    
    #
    # Decides whether or not to run a given module based on the<br/>
    # HTML elements it plans to audit and the existence of those elements<br/> 
    # in the current page.
    #
    # @see Page
    #
    # @param    [Class]   mod   the module to run
    # @param    [Page]    page
    #
    # @return    [Bool]
    #
    def run_module?( mod, page )
        
        checkpoint = 0
        page.elements( ).each_pair {
            |name, value|
            
            symbol = "audit_#{name}".to_sym
            if( !@opts[symbol] )
                next 
            end
            
            if( !mod.info || !mod.info['Elements'] ||
                mod.info['Elements'].size == 0 )
                return true
            end
            
            if( mod.info['Elements'].include?( 'cookie' ) )
                return true
            end
        
            if( mod.info['Elements'].include?( 'header' ) )
                return true
            end
                    
            if( mod.info['Elements'].include?( name.tr( 's', '' ) ) &&
                value.size != 0 )
                return true
            end
        }
        
        return false
    end
    
    #
    # Takes care of report execution
    #
    # @see AuditStore
    #
    # @param  [AuditStore]  audit_store
    #
    def run_reps( audit_store )
    
        ls_loaded_reps.each_with_index {
            |report, i|

            # choose a default report name
            if( !@opts[:repsave] || @opts[:repsave].size == 0 )
                @opts[:repsave] =
                    URI.parse( audit_store.options['url'] ).host +
                        '-' + Time.now.to_s
            end
            
            new_rep = report.new( deep_clone( audit_store ), @opts[:repopts],
                @opts[:repsave] + REPORT_EXT )
            
            new_rep.run( )
        }
    end

    
    #
    # Takes care of some options that need slight processing
    #
    def parse_opts(  )

        @opts.each do |opt, arg|

            case opt.to_s

                when 'arachni_verbose'
                    verbose!

                when 'debug'
                    debug!

                when 'only_positives'
                    only_positives!

                when 'cookie_jar'
                    @opts[:cookies] =
                        Arachni::Module::HTTP.parse_cookiejar( @opts[:cookie_jar] )

#                when 'delay'
#                    @opts[:delay] = Float.new( @opts[:delay] ) 

            end
        end

    end

    #
    # Validates options
    #
    # If something is out of order an exception will be raised.
    #
    def validate_opts

        if @opts[:repload] then return end
            
        if !@opts[:audit_links] &&
            !@opts[:audit_forms] &&
            !@opts[:audit_cookies] &&
            !@opts[:audit_headers]
            raise( Arachni::Exceptions::NoAuditOpts,
                "No audit options were specified." )
        end

        #
        # Ensure that the user selected some modules
        #
        if !@opts[:mods]
            raise( Arachni::Exceptions::NoMods, "No modules were specified." )
        end

        # Check for missing url
        if @opts[:url] == nil
            raise( Arachni::Exceptions::NoURL, "Missing url argument." )
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
            raise( Arachni::Exceptions::InvalidURL, "Invalid URL argument." )
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
            @opts[:threads] = 3
        end
        
        # make sure the provided cookie-jar file exists
        if @opts[:cookie_jar] && !File.exist?( @opts[:cookie_jar] )
            raise( Arachni::Exceptions::NoCookieJar,
                'Cookie-jar \'' + @opts[:cookie_jar] +
                        '\' doesn\'t exist.' )
        end
        
    end

    #
    # Creates a deep clone of an object and returns that object.
    #
    # @param    [Object]    the object to clone
    #
    # @return   [Object]    a deep clone of the object
    #
    def deep_clone( obj )
        YAML::load( obj.to_yaml )
    end
  
end

end
