=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end


require 'rubygems'

require File.expand_path( File.dirname( __FILE__ ) ) + '/options'
opts = Arachni::Options.instance

require opts.dir['lib'] + 'arachni'
require opts.dir['lib'] + 'ruby'
require opts.dir['lib'] + 'exceptions'
require opts.dir['lib'] + 'spider'
require opts.dir['lib'] + 'parser'
require opts.dir['lib'] + 'audit_store'
require opts.dir['lib'] + 'module'
require opts.dir['lib'] + 'plugin'
require opts.dir['lib'] + 'http'
require opts.dir['lib'] + 'report'
require opts.dir['lib'] + 'component_manager'
require 'yaml'
require 'ap'
require 'pp'


module Arachni

    #
    # Resets the Framework providing a clean slate.
    #
    # This is useful to user interfaces that require the framework to be reused.
    #
    def self.reset
        Element::Auditable.reset
        Module::Manager.reset
        Report::Manager.reset
        Arachni::HTTP.instance.reset
    end

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
# @version: 0.2.3
#
class Framework

    #
    # include the output interface but try to use it as little as possible
    #
    # the UI classes should take care of communicating with the user
    #
    include Arachni::UI::Output
    include Arachni::Module::Utilities
    include Arachni::Mixins::Observable

    # the version of *this* class
    REVISION     = '0.2.3'

    #
    # Instance options
    #
    # @return [Options]
    #
    attr_reader :opts

    #
    # @return   [Arachni::Report::Manager]   report manager
    #
    attr_reader :reports

    #
    # @return   [Arachni::Module::Manager]   module manager
    #
    attr_reader :modules

    #
    # @return   [Arachni::Plugin::Manager]   plugin manager
    #
    attr_reader :plugins

    #
    # @return   [Arachni::Spider]   spider
    #
    attr_reader :spider

    #
    # @return   [Arachni::HTTP]
    #
    attr_reader :http

    attr_reader :sitemap
    attr_reader :auditmap

    #
    # Holds candidate pages to be audited.
    #
    # Pages in the queue are pushed in by the trainer, the queue doesn't hold
    # pages returned by the spider.
    #
    # Plug-ins can push their own pages to be audited if they wish to...
    #
    # @return   [Queue<Arachni::Parser::Page>]   page queue
    #
    attr_reader :page_queue


    #
    # Initializes system components.
    #
    # @param    [Options]    opts
    #
    def initialize( opts )

        Encoding.default_external = "BINARY"
        Encoding.default_internal = "BINARY"

        @opts = opts

        @modules = Arachni::Module::Manager.new( @opts )
        @reports = Arachni::Report::Manager.new( @opts )
        @plugins = Arachni::Plugin::Manager.new( self )

        @page_queue = Queue.new

        prepare_cookie_jar( )
        prepare_user_agent( )

        # deep clone the redundancy rules to preserve their counter
        # for the reports
        @orig_redundant = @opts.redundant.deep_clone

        @running = false
        @paused  = []

        @plugin_store = {}

        @current_url = ''
    end

    def http
        Arachni::HTTP.instance
    end

    #
    # Runs the system
    #
    # It parses the instance options and runs the audit
    #
    # @param   [Block]     &block  a block to call after the audit has finished
    #                                   but before running the reports
    #
    def run( &block )
        @running = true

        @opts.start_datetime = Time.now

        # run all plugins
        @plugins.run

        # catch exceptions so that if something breaks down or the user opted to
        # exit the reports will still run with whatever results
        # Arachni managed to gather
        begin
            # start the audit
            audit( )
        rescue Exception
        end

        clean_up!
        begin
            block.call if block
        rescue Exception
        end

        # run reports
        if( @opts.reports && !@opts.reports.empty? )
            exception_jail{ @reports.run( audit_store( ) ) }
        end

        return true
    end

    def stats( refresh_time = false )
        req_cnt = http.request_count
        res_cnt = http.response_count

        @auditmap ||= []
        @sitemap  ||= []
        if !refresh_time || @auditmap.size == @sitemap.size
            @opts.delta_time ||= Time.now - @opts.start_datetime
        else
            @opts.delta_time = Time.now - @opts.start_datetime
        end

        curr_avg = 0
        if http.curr_res_cnt > 0 && http.curr_res_time > 0
            curr_avg = (http.curr_res_cnt / http.curr_res_time).to_i.to_s
        end

        avg = 0
        if res_cnt > 0
            avg = ( res_cnt / @opts.delta_time ).to_i.to_s
        end

        progress = (Float( @auditmap.size ) / @sitemap.size) * 100

        if Arachni::Module::Auditor.timeout_loaded_modules.size > 0 &&
            Arachni::Module::Auditor.timeout_audit_blocks.size > 0

            progress /= 2
            progress += ( Float( Arachni::Module::Auditor.timeout_loaded_modules.size ) /
                Arachni::Module::Auditor.timeout_audit_blocks.size ) * 50
        end

        return {
            :requests   => req_cnt,
            :responses  => res_cnt,
            :time_out_count  => http.time_out_count,
            :time       => audit_store.delta_time,
            :avg        => avg,
            :sitemap_size  => @sitemap.size,
            :auditmap_size => @auditmap.size,
            :progress      => progress.to_s[0...5],
            :curr_res_time => http.curr_res_time,
            :curr_res_cnt  => http.curr_res_cnt,
            :curr_avg      => curr_avg,
            :average_res_time => http.average_res_time,
            :max_concurrency  => http.max_concurrency,
            :current_page     => @current_url
        }
    end

    #
    # Audits the site.
    #
    # Runs the spider, analyzes each page as it appears and passes it
    # to (#run_mods} to be audited.
    #
    def audit

        wait_if_paused

        @spider = Arachni::Spider.new( @opts )

        @sitemap  ||= []
        @auditmap ||= []

        # initiates the crawl
        @spider.run {
            |page|

            @sitemap |= @spider.sitemap

            @page_queue << page
            audit_queue if !@opts.spider_first
        }

        audit_queue

        exception_jail {
            if !Arachni::Module::Auditor.timeout_audit_blocks.empty?
                print_line
                print_status( 'Running timing attacks.' )
                print_info( '---------------------------------------' )
                Arachni::Module::Auditor.timeout_audit_run
            end

            audit_queue
        }

        if( @opts.http_harvest_last )
            harvest_http_responses
        end

    end

    def audit_queue

        # this will run until no new elements appear for the given page
        while( !@page_queue.empty? && page = @page_queue.pop )

            # audit the page
            exception_jail{ run_mods( page ) }

            # run all the queued HTTP requests and harvest the responses
            http.run

            # check to see if the page was updated
            http.trainer.flush_pages.each {
                |page|
                @page_queue << page
            }

        end
    end


    #
    # Returns the results of the audit as an {AuditStore} instance
    #
    # @see AuditStore
    #
    # @return    [AuditStore]
    #
    def audit_store( fresh = false )

        # restore the original redundancy rules and their counters
        @opts.redundant = @orig_redundant
        opts = @opts.to_h
        opts['mods'] = @modules.keys

        if( !fresh && @store )
            return @store
        else
            return @store = AuditStore.new( {
                :version  => version( ),
                :revision => REVISION,
                :options  => opts,
                :sitemap  => @sitemap ? @sitemap.sort : ['N/A'],
                :issues   => @modules.results( ).deep_clone,
                :plugins  => @plugin_store
            }, self )
         end
    end

    def plugin_store( plugin, obj )
        name = ''
        @plugins.each_pair {
            |k, v|

            if plugin.class.name == v.name
                name = k
                break
            end
        }

        return if @plugin_store[name]

        @plugin_store[name] = {
            :results => obj
        }.merge( plugin.class.info )
    end

    #
    # Returns an array of hashes with information
    # about all available modules
    #
    # @return    [Array<Hash>]
    #
    def lsmod

        mod_info = []
        @modules.available( ).each {
            |name|

            path = @modules.name_to_path( name )
            next if !lsmod_match?( path )

            info = @modules[name].info( )

            info[:mod_name]    = name
            info[:name]        = info[:name].strip
            info[:description] = info[:description].strip

            if( !info[:dependencies] )
                info[:dependencies] = []
            end

            info[:author]    = info[:author].strip
            info[:version]   = info[:version].strip
            info[:path]      = path.strip

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

        rep_info = []
        @reports.available( ).each {
            |report|

            info = @reports[report].info

            info[:rep_name]    = report
            info[:path]        = @reports.name_to_path( report )

            rep_info << info
        }
        @reports.clear( )

        return rep_info
    end

    #
    # Returns an array of hashes with information
    # about all available reports
    #
    # @return    [Array<Hash>]
    #
    def lsplug

        plug_info = []

        @plugins.available( ).each {
            |plugin|

            info = @plugins[plugin].info

            info[:plug_name]   = plugin
            info[:path]        = @plugins.name_to_path( plugin )

            plug_info << info
        }

        @plugins.clear( )

        return plug_info
    end

    def running?
        @running
    end

    def paused?
        !@paused.empty?
    end

    def pause!
        @spider.pause! if @spider
        @paused << caller
        return true
    end

    def resume!
        @paused.delete( caller )
        @spider.resume! if @spider
        return true
    end

    #
    # Returns the version of the framework
    #
    # @return    [String]
    #
    def version
        Arachni::VERSION
    end

    #
    # Returns the revision of the {Framework} (this) class
    #
    # @return    [String]
    #
    def revision
        REVISION
    end

    def clean_up!( skip_audit_queue = false )
        @opts.finish_datetime = Time.now
        @opts.delta_time = @opts.finish_datetime - @opts.start_datetime

        # make sure this is disabled or it'll break report output
        @@only_positives = false

        @running = false

        # wait for the plugins to finish
        @plugins.block!

        # a plug-in may have updated the page queue, rock it!
        audit_queue if !skip_audit_queue

        # refresh the audit store
        audit_store( true )

        return true
    end

    private

    def caller
        if /^(.+?):(\d+)(?::in `(.*)')?/ =~ ::Kernel.caller[1]
            return Regexp.last_match[1]
        end
    end

    def wait_if_paused
        while( paused? )
            ::IO::select( nil, nil, nil, 1 )
        end
    end


    #
    # Prepares the user agent to be used throughout the system.
    #
    def prepare_user_agent
        if( !@opts.user_agent )
            @opts.user_agent = 'Arachni/' + version( )
        end

        if( @opts.authed_by )
            authed_by         = " (Scan authorized by: #{@opts.authed_by})"
            @opts.user_agent += authed_by
        end

    end

    def prepare_cookie_jar(  )
        return if !@opts.cookie_jar || !@opts.cookie_jar.is_a?( String )

        # make sure that the provided cookie-jar file exists
        if !File.exist?( @opts.cookie_jar )
            raise( Arachni::Exceptions::NoCookieJar,
                'Cookie-jar \'' + @opts.cookie_jar + '\' doesn\'t exist.' )
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

        print_line
        print_status( "Auditing: [HTTP: #{page.code}] " + page.url )


        call_on_run_mods( page.deep_clone )

        @current_url = page.url.to_s

        @modules.each_pair {
            |name, mod|
            wait_if_paused
            run_mod( mod, page.deep_clone )
        }

        @auditmap << page.url
        @auditmap.uniq!
        @sitemap |= @auditmap
        @sitemap.uniq!


        if( !@opts.http_harvest_last )
            harvest_http_responses( )
        end

    end

    def harvest_http_responses

        print_status( 'Harvesting HTTP responses...' )
        print_info( 'Depending on server responsiveness and network' +
            ' conditions this may take a while.' )

        # grab updated pages
        http.trainer.flush_pages.each {
            |page|
            @page_queue << page
        }

        # run all the queued HTTP requests and harvest the responses
        http.run

        http.trainer.flush_pages.each {
            |page|
            @page_queue << page
        }

        audit_queue
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
        return if !run_mod?( mod, page )

        begin

            # instantiate the module
            mod_new = mod.new( page )
            mod_new.set_framework( self )

            mod_new.prepare
            mod_new.run
            mod_new.clean_up
        rescue SystemExit
            raise
        rescue Exception => e
            print_error( 'Error in ' + mod.to_s + ': ' + e.to_s )
            print_debug_backtrace( e )
        end
    end

    #
    # Determines whether or not to run the module against the given page
    # depending on which elements exist in the page, which elements the module
    # is configured to audit and user options.
    #
    # @param    [Class]   mod      the module to run
    # @param    [Page]    page
    #
    # @return   [Bool]
    #
    def run_mod?( mod, page )
        return true if( !mod.info[:elements] || mod.info[:elements].empty? )

        elems = {
            Issue::Element::LINK => page.links && page.links.size > 0 && @opts.audit_links,
            Issue::Element::FORM => page.forms && page.forms.size > 0 && @opts.audit_forms,
            Issue::Element::COOKIE => page.cookies && page.cookies.size > 0 && @opts.audit_cookies,
            Issue::Element::HEADER => page.headers && page.headers.size > 0 && @opts.audit_headers,
            Issue::Element::BODY   => true,
            Issue::Element::PATH   => true,
            Issue::Element::SERVER => true,
        }

        elems.each_pair {
            |elem, expr|
            return true if mod.info[:elements].include?( elem ) && expr
        }

        return false
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
