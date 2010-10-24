=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end


require 'rubygems'

require File.expand_path( File.dirname( __FILE__ ) ) + '/options'
opts = Arachni::Options.instance

require opts.dir['lib'] + 'ruby'
require opts.dir['lib'] + 'exceptions'
require opts.dir['lib'] + 'spider'
require opts.dir['lib'] + 'parser'
require opts.dir['lib'] + 'audit_store'
require opts.dir['lib'] + 'vulnerability'
require opts.dir['lib'] + 'module'
require opts.dir['lib'] + 'report'
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
# user options.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.9
#
class Framework

    #
    # include the output interface but try to use it as little as possible
    #
    # the UI classes should take care of communicating with the user
    #
    include Arachni::UI::Output
    include Arachni::Module::Utilities

    # the universal system version
    VERSION      = '0.2.1'

    # the version of *this* class
    REVISION     = '0.1.9'

    #
    # Instance options
    #
    # @return [Options]
    #
    attr_reader :opts
    attr_reader :reports
    attr_reader :modules

    #
    # Initializes system components.
    #
    # @param    [Options]    opts
    #
    def initialize( opts )

        Encoding.default_external = "BINARY"
        Encoding.default_internal = "BINARY"

        @opts = opts

        @modules = Arachni::Module::Registry.new( @opts )
        @reports = Arachni::Report::Registry.new( @opts )

        parse_opts( )
        prepare_user_agent( )

        @spider   = Arachni::Spider.new( @opts )
        @parser   = Arachni::Parser.new( @opts )

        # deep clone the redundancy rules to preserve their counter
        # for the reports
        @orig_redundant = @opts.redundant.deep_clone

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

        @opts.start_datetime = Time.now

        # catch exceptions so that if something breaks down or the user opted to
        # exit the reports will still run with whatever results
        # Arachni managed to gather
        begin
            # start the audit
            audit( )
        rescue Exception

        end

        @opts.finish_datetime = Time.now
        @opts.delta_time = @opts.finish_datetime - @opts.start_datetime

        # run reports
        if( @opts.reports )
            exception_jail{ @reports.run( audit_store ) }
        end

        # save the AuditStore in a file
        if( @opts.repsave && !@opts.repload )
            exception_jail{ audit_store_save( @opts.repsave ) }
        end

    end

    def stats( )
        req_cnt = Arachni::Module::HTTP.instance.request_count
        res_cnt = Arachni::Module::HTTP.instance.response_count

        return {
            :requests   => req_cnt,
            :responses  => res_cnt,
            :time       => audit_store.delta_time,
            :avg        => ( req_cnt / @opts.delta_time ).to_i.to_s
        }
    end

    #
    # Audits the site.
    #
    # Runs the spider, analyzes each page as it appears and passes it
    # to (#run_mods} to be audited.
    #
    def audit
        pages = []

        # initiates the crawl
        @sitemap = @spider.run {
            | url, html, headers |

            exception_jail{
                run_mods( @parser.run( url, html, headers ).clone )
            }
        }

        if( @opts.http_harvest_last )
            harvest_http_responses( )
        end

    end


    #
    # Returns the results of the audit as an {AuditStore} instance
    #
    # @see AuditStore
    #
    # @return    [AuditStore]
    #
    def audit_store

        # restore the original redundacy rules and their counters
        @opts.redundant = @orig_redundant

        return AuditStore.new( {
            :version  => VERSION,
            :revision => REVISION,
            :options  => @opts.to_h,
            :sitemap  => @sitemap ? @sitemap.sort : ['N/A'],
            :vulns    => @modules.results( ).deep_clone
         } )
    end


    #
    # Saves an AuditStore instance in 'file'
    #
    # @param    [String]    file
    #
    def audit_store_save( file )

        file += @reports.extension

        print_line( )
        print_status( 'Dumping audit results in \'' + file  + '\'.' )

        audit_store.save( file )

        print_status( 'Done!' )
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

        @modules.available( ).each_pair {
            |mod_name, path|

            next if !lsmod_match?( path['path'] )

            @modules.load( mod_name )

            info = @modules.info( i )

            info[:mod_name]    = mod_name
            info[:name]        = info[:name].strip
            info[:description] = info[:description].strip

            if( !info[:dependencies] )
                info[:dependencies] = []
            end

            info[:author]    = info[:author].strip
            info[:version]   = info[:version].strip
            info[:path]      = path['path'].strip

            i+=1

            mod_info << info
        }

        # unload all modules
        @modules.clear( )

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

        @reports.available( ).each_pair {
            |rep_name, path|

            @reports.load( rep_name )

            info = @reports.info( i )

            info[:rep_name]    = rep_name
            info[:path]        = path['path'].strip

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
    # Returns the revision of the {Framework} (this) class
    #
    # @return    [String]
    #
    def revision
        REVISION
    end

    private

    #
    # Prepares the user agent to be used throughout the system.
    #
    def prepare_user_agent
        if( !@opts.user_agent )
            @opts.user_agent = 'Arachni/' + VERSION
        end

        if( @opts.authed_by )
            authed_by         = " (Scan authorized by: #{@opts.authed_by})"
            @opts.user_agent += authed_by
        end

    end

    #
    # Takes care of page audit and module execution
    #
    # It will audit one page at a time as discovered by the spider <br/>
    # and recursively check for new elements that may have <br/>
    # appeared during the audit.
    #
    # When no new elements appear the recursion will stop and a new page<br/>
    # will be accepted.
    #
    # @see Page
    #
    # @param    [Page]    page
    #
    def run_mods( page )
        return if !page

        for mod in @modules.loaded( )
            run_mod( mod, page.deep_clone )
        end

        if( !@opts.http_harvest_last )
            harvest_http_responses( )
        end

    end

    def harvest_http_responses

       print_status( 'Harvesting HTTP responses...' )
       print_info( 'Depending on server responsiveness and network' +
        ' conditions this may take a while.' )

       # run all the queued HTTP requests and harvest the responses
       Arachni::Module::HTTP.instance.run

       @page_queue ||= Queue.new

       # try to get an updated page from the Trainer
       page = Arachni::Module::Trainer.instance.page

       # if there was an updated page push it in the queue
       @page_queue << page if page

       # this will run until no new elements appear for the given page
       while( !@page_queue.empty? && page = @page_queue.pop )

           # audit the page
           run_mods( page )

           # run all the queued HTTP requests and harvest the responses
           Arachni::Module::HTTP.instance.run

           # check to see if the page was updated
           page = Arachni::Module::Trainer.instance.page
           # and push it in the queue to be audited as well
           @page_queue << page if page

       end

    end

    #
    # Passes a page to the module and runs it.<br/>
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

            # run the methods specified by the module API

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
    # Takes care of some options that need slight processing
    #
    def parse_opts(  )

        @opts.to_h.each do |opt, arg|

            case opt.to_s

                when 'arachni_verbose'
                    verbose!

                when 'debug'
                    debug!

                when 'only_positives'
                    only_positives!

                when 'cookie_jar'
                    @opts.cookies =
                        Arachni::Module::HTTP.parse_cookiejar( @opts.cookie_jar )

            end
        end

    end

    #
    # Validates options
    #
    # If something is out of order an exception will be raised.
    #
    def validate_opts

        if @opts.repload then return end

        if( !@opts.audit_links &&
            !@opts.audit_forms &&
            !@opts.audit_cookies &&
            !@opts.audit_headers
          )
            raise( Arachni::Exceptions::NoAuditOpts,
                "No audit options were specified." )
        end

        #
        # Ensure that the user selected some modules
        #
        if( !@opts.mods )
            raise( Arachni::Exceptions::NoMods, "No modules were specified." )
        end

        # Check for missing url
        if( @opts.url == nil )
            raise( Arachni::Exceptions::NoURL, "Missing url argument." )
        end

        #
        # Try and parse the URL.
        #
        begin
            require 'uri'
            @opts.url = URI.parse( URI.encode( @opts.url ) )
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

        # make sure that the provided cookie-jar file exists
        if @opts.cookie_jar && !File.exist?( @opts.cookie_jar )
            raise( Arachni::Exceptions::NoCookieJar,
                'Cookie-jar \'' + @opts.cookie_jar +
                        '\' doesn\'t exist.' )
        end

    end

    def lsmod_match?( path )
        cnt = 0
        @opts.lsmod.each {
            |filter|
            cnt += 1 if path =~ filter
        }
        return true if cnt == @opts.lsmod.size
    end

end

end
