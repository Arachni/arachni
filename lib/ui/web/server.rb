=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'webrick'
require 'webrick/https'
require 'openssl'

require 'sinatra/base'
require "rack/csrf"
require 'rack-flash'
require 'json'
require 'erb'
require 'yaml'
require 'cgi'
require 'fileutils'
require 'ap'


module Arachni
module UI

require Arachni::Options.instance.dir['lib'] + 'ui/cli/output'
require Arachni::Options.instance.dir['lib'] + 'framework'
require Arachni::Options.instance.dir['lib'] + 'ui/web/utilities'
require Arachni::Options.instance.dir['lib'] + 'ui/web/report_manager'
require Arachni::Options.instance.dir['lib'] + 'ui/web/dispatcher_manager'
require Arachni::Options.instance.dir['lib'] + 'ui/web/instance_manager'
require Arachni::Options.instance.dir['lib'] + 'ui/web/scheduler'
require Arachni::Options.instance.dir['lib'] + 'ui/web/log'
require Arachni::Options.instance.dir['lib'] + 'ui/web/output_stream'

require Arachni::Options.instance.dir['lib'] + 'ui/web/addon_manager'

#
#
# Provides a web user interface for the Arachni Framework using Sinatra.
#
# It's basically an XMLRPC client for Dispatchers and Instances wearing a pretty frock.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
#
# @see Arachni::RPC::XML::Client::Instance
# @see Arachni::RPC::XML::Client::Dispatcher
#
module Web

    VERSION = '0.2.1'

class Server < Sinatra::Base

    include Utilities

    configure do
        use Rack::Flash
        use Rack::Session::Cookie
        use Rack::Csrf, :raise => true

        @@conf = YAML::load_file( Arachni::Options.instance.dir['root'] + 'conf/webui.yaml' )
        Arachni::Options.instance.ssl      = @@conf['ssl']['client']['enable']
        Arachni::Options.instance.ssl_pkey = @@conf['ssl']['client']['key']
        Arachni::Options.instance.ssl_cert = @@conf['ssl']['client']['cert']
        Arachni::Options.instance.ssl_ca   = @@conf['ssl']['client']['ca']

    end

    helpers do

        def title
            main = 'Arachni - Web Application Security Scanner Framework'

            sub = env['PATH_INFO'].split( '/' ).map {
                |part|
                normalize_section_name( part )
            }.reject { |part| part.empty? }.join( ' &rarr; ' )

            return sub.empty? ? main : sub + ' :: ' + main
        end

        def normalize_section_name( name )
            name.gsub( '_', ' ' ).capitalize
        end

        def job_is_slave?( job )
            job['helpers']['rank'] == 'slave'
        end

        def report_count
            reports.all.size
        end

        def plugin_has_required_file_option?( options )
            options.each {
                |opt|
                return true if opt['type'] == 'path' && opt['required']
            }

            return false
        end

        def format_redundants( rules )
            return if !rules || !rules.is_a?( Array ) || rules.empty?

            str = ''
            rules.each {
                |rule|
                next if !rule['regexp'] || !rule['count']
                str += rule['regexp'] + ':' + rule['count'] + "\r\n"
            }
            return str
        end

        def prep_description( str )
            placeholder =  '--' + rand( 1000 ).to_s + '--'
            cstr = str.gsub( /^\s*$/xm, placeholder )
            cstr.gsub!( /^\s*/xm, '' )
            cstr.gsub!( placeholder, "\n" )
            cstr.chomp
        end

        def selected_tab?( tab )
            splits = env['PATH_INFO'].split( '/' )
            ( splits.empty? && tab == '/' ) || splits[1] == tab
        end

        def csrf_token
            Rack::Csrf.csrf_token( env )
        end

        def csrf_tag
            Rack::Csrf.csrf_tag( env )
        end

        def modules
            @@modules
        end

        def plugins
            @@plugins
        end

        def proc_mem( rss )
            # we assume a page size of 4096
            rss.to_i * 4096 / 1024 / 1024
        end

        def secs_to_hms( secs )
            secs = secs.to_i
            return [secs/3600, secs/60 % 60, secs % 60].map {
                |t|
                t.to_s.rjust( 2, '0' )
            }.join(':')
        end

    end


    dir = File.dirname( File.expand_path( __FILE__ ) )

    set :views,  "#{dir}/server/views"
    set :public, "#{dir}/server/public"
    set :tmp,    "#{dir}/server/tmp"
    set :db,     "#{dir}/server/db"
    set :static, true
    set :environment, :development

    #
    # This will be used for the "owner" field of the helper instance
    #
    HELPER_OWNER =  "WebUI helper"

    enable :sessions

    set :log,     Log.new( Arachni::Options.instance, settings )
    set :reports, ReportManager.new( Arachni::Options.instance, settings )
    set :dispatchers, DispatcherManager.new( Arachni::Options.instance, settings )
    set :instances,   InstanceManager.new( Arachni::Options.instance, settings )
    set :scheduler,   Scheduler.new( Arachni::Options.instance, settings )
    set :addons,     AddonManager.new( Arachni::Options.instance, settings )

    configure do
        # shit's on!
        log.webui_started
    end

    def addons
        settings.addons
    end

    def log
        settings.log
    end

    def reports
        settings.reports
    end

    def dispatchers
        settings.dispatchers
    end

    #
    # Provides statistics about running jobs etc using the dispatcher
    #
    def dispatcher_stats
        dispatchers.stats
    end

    def scheduler
        settings.scheduler
    end

    def instances
        settings.instances
    end

    def exception_jail( &block )
        # begin
            block.call
        # rescue Errno::ECONNREFUSED => e
        #     erb :error, { :layout => true }, :error => 'Remote server has been shut down.'
        # end
    end

    def show( page, layout = true )
        if page == :dispatchers
            ensure_dispatcher
            erb :dispatchers, { :layout => true }, :stats => dispatcher_stats
        else
            erb page.to_sym, { :layout => layout }
        end
    end

    def show_dispatcher_line( stats )

        str = "@#{escape( stats['node']['url'] )} - #{stats['running_jobs'].size} running scans, "

        i=0
        stats['running_jobs'].each {
            |job|
            i+= proc_mem( job['proc']['rss'] ).to_i
        }
        str += i.to_s + 'MB RAM usage '

        i=0
        stats['running_jobs'].each {
            |job|
            i+= Float( job['proc']['pctmem'] )
        }
        str += '(' + i.to_s[0..4] + '%), '

        i=0
        stats['running_jobs'].each {
            |job|
            i+= Float( job['proc']['pctcpu'] )
        }
        str += i.to_s[0..4] + '% CPU usage'
    end

    def show_dispatcher_node_line( stats )
        str = "Nickname: #{stats['node']['nickname']} - "
        str += "Pipe ID: #{stats['node']['pipe_id']} - "
        str += "Weight: #{stats['node']['weight']} - "
        str += "Cost: #{stats['node']['cost']} "
    end

    def welcomed?
        File.exist?( settings.db + '/welcomed' )
    end

    def welcomed!
        File.new( settings.db + '/welcomed', 'w' ).close
    end

    def ensure_welcomed
        return if welcomed?

        welcomed!
        redirect '/welcome'
    end

    def options
        Arachni::Options.instance
    end

    #
    # Similar to String.to_i but it returns the original object if String is not a number
    #
    def to_i( str )
        return str if !str.is_a?( String )

        if str.match( /\d+/ ).to_s.size == str.size
            return str.to_i
        else
            return str
        end
    end

    #
    # Prepares form params to be used as options for XMLRPC transmission
    #
    # @param    [Hash]  params
    #
    # @return   [Hash]  normalized hash
    #
    def prep_opts( params )

        need_to_split = [
            'exclude_cookies',
            'exclude',
            'include'
        ]

        cparams = {}
        params.each_pair {
            |name, value|

            next if [ '_csrf', 'modules', 'plugins' ].include?( name ) || ( value.is_a?( String ) && value.empty?)

            value = true if value == 'on'

            if name == 'cookiejar'
               cparams['cookies'] = Arachni::HTTP.parse_cookiejar( value[:tempfile] )
            elsif need_to_split.include?( name ) && value.is_a?( String )
                cparams[name] = value.split( "\r\n" )

            elsif name == 'redundant'
                cparams[name] = []
                value.split( "\r\n" ).each {
                    |rule|
                    regexp, counter = rule.split( ':', 2 )
                    cparams[name] << {
                        'regexp'  => regexp,
                        'count'   => counter
                    }
                }
            else
                cparams[name] = to_i( value )
            end
        }

        if !cparams['audit_links'] && !cparams['audit_forms'] &&
              !cparams['audit_cookies'] && !cparams['audit_headers']

            cparams['audit_links']   = true
            cparams['audit_forms']   = true
            cparams['audit_cookies'] = true
        end

        return cparams
    end

    def prep_modules( params )
        return ['-'] if !params['modules']
        mods = params['modules'].keys
        return ['*'] if mods.empty?
        return mods
    end

    def prep_plugins( params )
        plugins  = {}

        return plugins if !params['plugins']
        params['plugins'].keys.each {
            |name|
            plugins[name] = params['options'][name] || {}
        }

        return plugins
    end

    def helper_instance
        begin
            @@arachni ||= nil
            if !@@arachni

                d_url = dispatchers.first_alive.url

                instance = dispatchers.connect( d_url ).dispatch( HELPER_OWNER )
                instance_url = instances.port_to_url( instance['port'], d_url )

                @@arachni = instances.connect( instance_url, session, instance['token'] )
            end

            return @@arachni
        rescue Exception => e
            # ap e
            # ap e.backtrace
            redirect '/dispatchers/edit'
        end
    end

    def component_cache_filled?
        begin
            return @@modules.size + @@plugins.size
        rescue
            return false
        end
    end

    def fill_component_cache

        if !component_cache_filled?
            do_shutdown = true
        else
            do_shutdown = false
        end

        @@modules ||= helper_instance.framework.lsmod.dup
        @@plugins ||= helper_instance.framework.lsplug.dup

        # shutdown the helper instance, we got what we wanted
        helper_instance.service.shutdown! if do_shutdown
    end

    #
    # Makes sure that all systems are go and populates the session with default values
    #
    def prep_session
        ensure_dispatcher

        session['opts'] ||= {}
        session['opts']['settings'] ||= {
            'audit_links'    => true,
            'audit_forms'    => true,
            'audit_cookies'  => true,
            'http_req_limit' => 20,
            'user_agent'     => 'Arachni/' + Arachni::VERSION
        }
        session['opts']['modules'] ||= [ '*' ]
        session['opts']['plugins'] ||= YAML::dump( {
            'content_types' => {},
            'healthmap'     => {},
            'metamodules'   => {}
        } )


        #
        # Garbage collector, zombie killer. Reaps idle processes every 5 seconds.
        #
        @@reaper ||= Thread.new {
            while( true )
                shutdown_zombies
                ::IO::select( nil, nil, nil, 5 )
            end
        }

    end

    #
    # Makes sure that we have a dispatcher, if not it redirects the user to
    # an appropriate error page.
    #
    # @return   [Bool]  true if alive, redirect if not
    #
    def ensure_dispatcher
        redirect '/dispatchers/edit' if !dispatchers.first_alive
    end

    #
    # Saves the report, shuts down the instance and returns the content as HTML
    # to be sent back to the user's browser.
    #
    # @param    [Arachni::RPC::XML::Client::Instance]   arachni
    #
    def save_shutdown_and_show( arachni )
        report = save_and_shutdown( arachni )
        reports.get( 'html', reports.all.last.id )
    end

    #
    # Saves the report and shuts down the instance
    #
    # @param    [Arachni::RPC::XML::Client::Instance]   arachni
    #
    def save_and_shutdown( arachni )
        begin
            arachni.framework.clean_up!( true )
            report_path = reports.save( arachni.framework.auditstore )
            3.times {
                begin
                    arachni.service.shutdown!
                    break
                rescue Timeout::Error
                end
            }
        rescue Exception => e
            ap e
            # ap e.faultCode
            # ap e.faultString
            ap e.backtrace
        end
        return report_path
    end

    #
    # Kills all running instances
    #
    def shutdown_all( url )
        log.dispatcher_global_shutdown( env, url )

        dispatcher_stats.each_pair {
            |d_url, stats|

            next if remove_proto( d_url.dup ) != url

            stats['running_jobs'].each {
                |job|
                next if job['helpers']['rank'] == 'slave'

                instance_url = instances.port_to_url( job['port'], d_url )
                begin
                    save_and_shutdown( instances.connect( instance_url, session ) )
                rescue
                    begin
                        instances.connect( instance_url, session ).service.shutdown!
                    rescue
                        log.instance_fucker_wont_die( env, instance_url )
                        next
                    end
                end

                log.instance_shutdown( env, instance_url )
            }
        }

    end

    #
    # Kills all idle instances
    #
    # @return    [Integer]  the number of reaped instances
    #
    def shutdown_zombies
        i = 0

        dispatcher_stats.each_pair {
            |url, stats|

            stats['running_jobs'].each {
                |job|
                next if job['helpers']['rank'] == 'slave'

                begin
                    instance_url = instances.port_to_url( job['port'], url )
                    arachni = instances.connect( instance_url, session )

                    begin
                        if !arachni.framework.busy? && !job['owner'] != HELPER_OWNER
                            save_and_shutdown( arachni )
                            log.webui_zombie_cleanup( env, instance_url )
                            i+=1
                        end
                    rescue
                    end

                rescue
                end
            }
        }

        return i
    end

    get "/" do
        prep_session
        ensure_welcomed
        show :home
    end

    get "/welcome" do
        erb :welcome, { :layout => true }
    end

    get "/dispatchers" do
        show :dispatchers
    end

    #
    # sets the dispatcher URL
    #
    post "/dispatchers" do

        if !params['url'] || params['url'].empty?
            flash[:err] = "URL cannot be empty."
            show :dispatchers_edit
        else
            log.dispatcher_selected( env, params['url'] )
            begin
                dispatchers.connect( url ).jobs
                log.dispatcher_verified( env, params['url'] )
                redirect '/'
            rescue
                log.dispatcher_error( env, params['url'] )
                flash[:err] = "Couldn't find a dispatcher at \"#{escape( params['url'] )}\"."
                show :dispatchers_edit
            end
        end
    end

    get '/dispatchers/edit' do
      show :dispatchers_edit
    end

    post '/dispatchers/add' do

        if dispatchers.alive?( params[:url] )
            dispatchers.new( params[:url] )
        else
            flash[:err] = "Couldn't find a dispatcher at \"#{escape( params['url'] )}\"."
        end

        show :dispatchers_edit
    end

    post '/dispatchers/:url/delete' do
        dispatchers.delete( params[:url] )
        show :dispatchers_edit
    end


    #
    # shuts down all instances
    #
    post "/dispatchers/:url/shutdown_all" do
        shutdown_all( params[:url] )
        redirect '/dispatchers'
    end


    get '/dispatchers/error' do
        show :dispatchers_edit
    end

    #
    # starts a scan
    #
    post "/scan" do

        valid = true
        begin
            URI.parse( params['url'] )
        rescue
            valid = false
        end

        if !params['url'] || params['url'].empty?
            flash[:err] = "URL cannot be empty."
            show :home
        elsif !valid
            flash[:err] = "Invalid URL."
            show :home
        elsif !params['dispatcher'] || params['dispatcher'].empty?
            flash[:err] = "Please select a Dispatcher."
            show :home
        else

            session['opts']['settings']['url'] = params[:url]

            unescape_hash( session['opts'] )
            session['opts']['settings']['audit_links']   = true if session['opts']['settings']['audit_links']
            session['opts']['settings']['audit_forms']   = true if session['opts']['settings']['audit_forms']
            session['opts']['settings']['audit_cookies'] = true if session['opts']['settings']['audit_cookies']
            session['opts']['settings']['audit_headers'] = true if session['opts']['settings']['audit_headers']

            opts = {}
            opts['settings'] = prep_opts( session['opts']['settings'] )
            opts['plugins']  = YAML::load( session['opts']['plugins'] )
            opts['modules']  = session['opts']['modules']

            job = Scheduler::Job.new(
                :dispatcher  => params[:dispatcher],
                :url         => params[:url],
                :opts        => opts.to_yaml,
                :owner_addr  => env['REMOTE_ADDR'],
                :owner_host  => env['REMOTE_HOST'],
                :created_at  => Time.now
            )

            instance_url = scheduler.run( job, env, session )
            redirect '/instance/' + instance_url.to_s.gsub( 'https://', '' )
        end
    end

    get "/modules" do
        fill_component_cache
        prep_session
        show :modules, true
    end

    #
    # sets modules
    #
    post "/modules" do
        session['opts']['modules'] = prep_modules( escape_hash( params ) )
        flash.now[:ok] = "Modules updated."
        show :modules, true
    end

    get "/plugins" do
        fill_component_cache
        prep_session
        erb :plugins, { :layout => true }, :session_options => YAML::load( session['opts']['plugins'] )
    end

    #
    # sets plugins
    #
    post "/plugins" do
        session['opts']['plugins'] = YAML::dump( prep_plugins( escape_hash( params ) ) )
        flash.now[:ok] = "Plugins updated."
        erb :plugins, { :layout => true }, :session_options => YAML::load( session['opts']['plugins'] )
    end

    get "/settings" do
        prep_session
        erb :settings, { :layout => true }
    end

    #
    # sets general framework settings
    #
    post "/settings" do

        if session['opts']['settings']['url']
            url = session['opts']['settings']['url'].dup
        end

         session['opts']['settings'] = prep_opts( escape_hash( params ) )

        if session['opts']['settings']['url']
            session['opts']['settings']['url'] = url
        end

        flash.now[:ok] = "Settings updated."
        show :settings, true
    end

    get "/instance/:url" do
        begin
            arachni = instances.connect( params[:url], session )
            erb :instance, { :layout => true }, :paused => arachni.framework.paused?, :shutdown => false
        rescue Exception => e
            flash.now[:notice] = "Instance at #{params[:url]} has been shutdown."
            erb :instance, { :layout => true }, :shutdown => true
        end

    end

    get "/instance/:url/output.json" do
        content_type :json

        output = {
            'messages' => {},
            'issues'   => {},
            'stats'    => {}
        }

        arachni = instances.connect( params[:url], session )
        begin
            if arachni.framework.busy?

                prog = arachni.framework.progress_data

                @@output_streams ||= {}
                @@output_streams[params[:url]] = OutputStream.new( prog['messages'], 38 )
                output['messages'] = { 'data' => @@output_streams[params[:url]].format }
                output['issues'] = { 'data' => erb( :output_results, { :layout => false }, :issues => YAML.load( prog['issues'] ) ) }

                output['stats'] = prog['stats'].dup

                output['stats']['current_pages'] = []
                if prog['stats']['current_pages']
                    prog['stats']['current_pages'].each {
                        |url|
                        output['stats']['current_pages'] << escape( url )
                    }
                end
            else
                log.instance_shutdown( env, params[:url] )
                save_and_shutdown( arachni )
                output['messages'] = { 'status' => 'finished', 'data' => "The server has been shut down." }
            end
        rescue IOError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
               Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
            output['messages'] = { 'data' => "<strong>Connection error, retrying...</strong>" }
            output['issues']   = { 'data' => "<strong>Connection error, retrying...</strong>" }
        rescue Exception => e
            ap e
            # ap e.faultCode
            # ap e.faultString
            ap e.backtrace
            output['messages'] = { 'status' => 'finished', 'data' => "The server has been shut down." }
        end


        # begin
            # # arachni = instances.connect( params[:url], session )
            # if !arachni.framework.paused? && arachni.framework.busy?
                # out = erb( :output_results, { :layout => false }, :issues => YAML.load( arachni.framework.issues ) )
                # output['issues'] = { 'data' => out }
            # end
        # rescue IOError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
               # Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
            # output['issues'] = { 'data' => "<strong>Connection error, retrying...</strong>" }
        # rescue Exception => e
            # ap e
            # ap e.backtrace
            # output['issues'] = { 'data' => "The server has been shut down." }
        # end


        # begin
            # # arachni = instances.connect( params[:url], session )
            # stats = arachni.framework.stats( true )
            # stats['current_page'] = escape( stats['current_page'] )
            # output['stats'] = stats
        # rescue
        # end

        output.to_json
    end


    post "/*/:url/pause" do
        arachni = instances.connect( params[:url], session )

        begin
            arachni.framework.pause!
            log.instance_paused( env, params[:url] )

            flash.now[:notice] = "Instance at #{params[:url]} will pause as soon as the current page is audited."
            erb params[:splat][0].to_sym, { :layout => true }, :paused => arachni.framework.paused?, :shutdown => false, :stats => dispatcher_stats
        rescue
            flash.now[:notice] = "Instance at #{params[:url]} has been shutdown."
            erb params[:splat][0].to_sym, { :layout => true }, :shutdown => true, :stats => dispatcher_stats
        end

    end

    post "/*/:url/resume" do
        arachni = instances.connect( params[:url], session )

        begin
            arachni.framework.resume!
            log.instance_resumed( env, params[:url] )

            flash.now[:notice] = "Instance at #{params[:url]} resumes."
            erb params[:splat][0].to_sym, { :layout => true }, :paused => arachni.framework.paused?, :shutdown => false, :stats => dispatcher_stats
        rescue
            flash.now[:notice] = "Instance at #{params[:url]} has been shutdown."
            erb params[:splat][0].to_sym, { :layout => true }, :shutdown => true, :stats => dispatcher_stats
        end
    end

    post "/*/:url/shutdown" do
        arachni = instances.connect( params[:url], session )

        begin
            arachni.framework.busy?
            log.instance_shutdown( env, params[:url] )

            begin
                save_shutdown_and_show( arachni )
            rescue
                flash.now[:notice] = "Instance at #{params[:url]} has been shutdown."
                show params[:splat][0].to_sym
            ensure
                arachni.service.shutdown!
            end
        rescue
            flash.now[:notice] = "Instance at #{params[:url]} has been shutdown."
            erb params[:splat][0].to_sym, { :layout => true }, :shutdown => true, :stats => dispatcher_stats
        end
    end

    get "/reports" do
        erb :reports, { :layout => true }, :reports => reports.all( :order => :datestamp.desc ),
            :available => reports.available
    end

    get '/reports/formats' do
        erb :report_formats, { :layout => true }, :reports => reports.available
    end

    post '/reports/delete' do
        reports.delete_all
        log.reports_deleted( env )

        redirect '/reports'
    end

    post '/report/:id/delete' do
        reports.delete( params[:id] )
        log.report_deleted( env, params[:id] )

        redirect '/reports'
    end

    get '/report/:id.:type' do
        log.report_converted( env, params[:id] + '.' + params[:type] )
        content_type( params[:type], :default => 'application/octet-stream' )
        reports.get( params[:type], params[:id] )
    end

    get '/log' do
        erb :log, { :layout => true }, :entries => log.entry.all.reverse
    end

    get '/addons' do
        erb :addons
    end

    post '/addons' do
        params['addons'] ||= {}
        addon_names = params['addons'].keys

        addons.enable!( addon_names )
        erb :addons
    end


    # override run! using this patch: https://github.com/sinatra/sinatra/pull/132
    def self.run!( options = {} )
        set options

        handler = detect_rack_handler
        handler_name = handler.name.gsub( /.*::/, '' )

        # handler specific options use the lower case handler name as hash key, if present
        handler_opts = options[handler_name.downcase.to_sym] || {}

        puts "== Sinatra/#{Sinatra::VERSION} has taken the stage " +
            "on #{port} for #{environment} with backup from #{handler_name}" unless handler_name =~/cgi/i

        handler.run self, handler_opts.merge( :Host => bind, :Port => port ) do |server|
            [ :INT, :TERM ].each { |sig| trap( sig ) { quit!( server, handler_name ) } }

            set :running, true
        end
    rescue Errno::EADDRINUSE => e
        puts "== Someone is already performing on port #{port}!"
    end

    def self.prep_webrick
        if @@conf['ssl']['server']['key']
            pkey = ::OpenSSL::PKey::RSA.new( File.read( @@conf['ssl']['server']['key'] ) )
        end

        if @@conf['ssl']['server']['cert']
            cert = ::OpenSSL::X509::Certificate.new( File.read( @@conf['ssl']['server']['cert'] ) )
        end

        if @@conf['ssl']['key'] || @@conf['ssl']['cert'] || @@conf['ssl']['ca']
            verification = OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
        else
            verification = ::OpenSSL::SSL::VERIFY_NONE
        end

        return {
            :SSLEnable       => @@conf['ssl']['server']['enable'] || false,
            :SSLVerifyClient => verification,
            :SSLCertName     => [ [ "CN", Arachni::Options.instance.server || ::WEBrick::Utils::getservername ] ],
            :SSLCertificate  => cert,
            :SSLPrivateKey   => pkey,
            :SSLCACertificateFile => @@conf['ssl']['server']['ca']
        }
    end

    run! :host    => Arachni::Options.instance.server   || ::WEBrick::Utils::getservername,
         :port    => Arachni::Options.instance.rpc_port || 4567,
         :server => %w[ webrick ],
         :webrick => prep_webrick

    at_exit do

        log.webui_shutdown

        begin
            # shutdown our helper instance
            @@arachni ||= nil
            @@arachni.service.shutdown! if @@arachni
        rescue
        end

    end

end

end
end
end
