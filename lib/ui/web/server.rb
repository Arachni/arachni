=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'eventmachine'
require 'em-synchrony'
require 'sinatra/base'
require 'sinatra/async'
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
# @see Arachni::RPC::Client::Instance
# @see Arachni::RPC::Client::Dispatcher
#
module Web

    VERSION = '0.3'

class Server < Sinatra::Base

    register Sinatra::Async

    include Arachni::Module::Utilities
    include Utilities

    configure do
        use Rack::Flash
        use Rack::Session::Cookie
        use Rack::Csrf, :raise => true

        opts = Arachni::Options.instance

        if opts.webui_username && opts.webui_password
            use Rack::Auth::Basic, "Arachni WebUI v" + Arachni::UI::Web::VERSION + " requires authentication." do |username, password|
                [username, password] == [ opts.webui_username, opts.webui_password ]
            end
        end

        @@conf = YAML::load_file( opts.dir['root'] + 'conf/webui.yaml' )
        opts.ssl      = @@conf['ssl']['client']['enable']
        opts.ssl_pkey = @@conf['ssl']['client']['key']
        opts.ssl_cert = @@conf['ssl']['client']['cert']
        opts.ssl_ca   = @@conf['ssl']['client']['ca']

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

        case page
            when :dispatchers
                ensure_dispatcher
                dispatcher.stats {
                    |stats|
                    erb :dispatchers
                }

            when :home
                dispatchers.stats {
                    |stats|
                    body erb page, { :layout => true }, :stats => stats
                }
            else
                erb page.to_sym, { :layout => layout }
        end
    end

    def show_dispatcher_line( stats )

        str = "#{escape( '@' + stats['node']['url'] )}" +
            " - #{stats['running_jobs'].size} running scans, "

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

    def helper_instance( &block )
        raise( "This method requires a block!" ) if !block_given?

        dispatchers.first_alive{
            |dispatcher|
            if !dispatcher
                async_redirect '/dispatchers/edit'
            else
                dispatchers.connect( dispatcher.url ).dispatch( HELPER_OWNER ){
                    |instance|
                    @@arachni = instances.connect( instance['url'], session, instance['token'] )
                    block.call( @@arachni )
                }
            end
        }
    end

    def component_cache_filled?
        begin
            return @@modules.size + @@plugins.size
        rescue
            return false
        end
    end

    def fill_component_cache( &block )
        if !component_cache_filled?


            helper_instance{
                |inst|

                inst.framework.lsmod {
                    |mods|

                    @@modules = mods.map { |mod| hash_keys_to_str( mod ) }

                    inst.framework.lsplug {
                        |plugs|

                        @@plugins = plugs.map { |plug| hash_keys_to_str( plug ) }

                        # shutdown the helper instance, we got what we wanted
                        inst.service.shutdown!{
                            block.call
                        }
                    }
                }
            }

        else
            block.call
        end
    end

    #
    # Makes sure that all systems are go and populates the session with default values
    #
    def prep_session
        session[:flash] = {}

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
        # Garbage collector, zombie killer. Reaps idle processes every 60 seconds.
        #
        ::EM.add_periodic_timer( 60 ){ ::EM.defer { shutdown_zombies } }
    end

    def async_redirect( location, opts = {} )
        response.status = 302

        if ( flash = opts[:flash] ) && !flash.empty?
            location += "?#{flash.keys[0]}=#{URI.encode( flash.values[0] )}"
        end

        response.headers['Location'] = location

        body ''
    end

    #
    # Makes sure that we have a dispatcher, if not it redirects the user to
    # an appropriate error page.
    #
    # @return   [Bool]  true if alive, redirect if not
    #
    def ensure_dispatcher
        dispatchers.first_alive {
            |dispatcher|
            async_redirect '/dispatchers/edit' if !dispatcher
        }
    end

    #
    # Saves the report and shuts down the instance
    #
    # @param    [Arachni::RPC::Client::Instance]   arachni
    #
    def save_and_shutdown( arachni, &block )
        arachni.framework.clean_up!{
            |res|
            if !res.rpc_connection_error?
                arachni.framework.auditstore {
                    |auditstore|
                    if !auditstore.rpc_connection_error?
                        report_path = reports.save( auditstore )
                        arachni.service.shutdown!{ block.call( report_path ) }
                    end
                }
            else
                block.call( res )
            end
        }
    end

    #
    # Kills all running instances
    #
    def shutdown_all( url, &block )
        log.dispatcher_global_shutdown( env, url )

        dispatchers.connect( url ).stats {
            |stats|
            stats['running_jobs'].each {
                |instance|

                next if instance['helpers']['rank'] == 'slave'
                save_and_shutdown( instances.connect( instance['url'], session ) ){
                    log.instance_shutdown( env, instance['url'] )
                }
            }
            block.call
        }
    end

    #
    # Kills all idle instances
    #
    # @return    [Integer]  the number of reaped instances
    #
    def shutdown_zombies
        dispatchers.jobs {
            |jobs|
            jobs.each {
                |job|
                next if job['helpers']['rank'] == 'slave' ||
                    job['owner'] == HELPER_OWNER

                arachni = instances.connect( job['url'], session )
                arachni.framework.busy? {
                    |busy|
                    if !busy
                        save_and_shutdown( arachni ){
                            log.webui_zombie_cleanup( env, job['url'] )
                        }
                    end
                }
            }
        }
    end

    aget "/" do
        prep_session
        ensure_welcomed
        dispatchers.stats {
            |stats|
            body erb :home, { :layout => true }, :stats => stats
        }
    end

    aget "/welcome" do
        body erb :welcome, { :layout => true }
    end

    aget "/dispatchers" do
        ensure_dispatcher
        dispatchers.stats {
            |stats|
            body erb :dispatchers, { :layout => true }, :stats => stats
        }
    end

    aget '/dispatchers/edit' do
        dispatchers.all_with_liveness {
            |dispatchers|
            body erb :dispatchers_edit, { :layout => true }, :dispatchers => dispatchers
      }
    end

    apost '/dispatchers/add' do
        dispatchers.alive?( params[:url] ) {
            |a|
            if a
                dispatchers.new( params[:url] )
                async_redirect '/dispatchers/edit'
            else
                msg = "Couldn't find a dispatcher at \"#{escape( params['url'] )}\"."
                async_redirect '/dispatchers/edit', :flash => { :err => msg }
            end
        }
    end

    apost '/dispatchers/:url/delete' do |url|
        dispatchers.delete( url )
        redirect '/dispatchers/edit'
    end

    aget '/dispatchers/:url/log.json' do |url|
        content_type :json

        begin
            dispatchers.connect( url ).log {
                |log|
                json = { 'log' => log }.to_json
                body json
            }
        rescue Exception => e
            json = { 'error' => e.to_s, 'backtrace' => e.backtrace.join( "\n" ),  }.to_json
            body json
        end
    end

    #
    # shuts down all instances
    #
    apost "/dispatchers/:url/shutdown_all" do |url|
        shutdown_all( url ){
            async_redirect '/dispatchers'
        }
    end

    #
    # starts a scan
    #
    apost "/scan" do

        valid = true
        begin
            URI.parse( params['url'] )
        rescue
            valid = false
        end

        if !params['url'] || params['url'].empty?
            async_redirect '/', :flash => { :err => "URL cannot be empty." }
        elsif !valid
            async_redirect '/', :flash => { :err => "Invalid URL." }
        elsif !params['dispatcher'] || params['dispatcher'].empty?
            async_redirect '/', :flash => { :err => "Please select a Dispatcher." }
        # elsif params['high_performance'] && neighbours.empty?
            # msg = "The selected Dispatcher can't be used " +
                # "in High Performance mode because it has no neighbours " +
                # "(i.e. is not pat of any Grid)."
            # async_redirect '/', :flash => { :err => msg }
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

            if params['high_performance']
                opts['settings']['grid_mode'] = 'high_performance'
            end


            job = Scheduler::Job.new(
                :dispatcher  => params[:dispatcher],
                :url         => params[:url],
                :opts        => opts.to_yaml,
                :owner_addr  => env['REMOTE_ADDR'],
                :owner_host  => env['REMOTE_HOST'],
                :created_at  => Time.now
            )

            scheduler.run( job, env, session ){
                |instance_url|
                async_redirect '/instance/' + instance_url
            }
        end
    end

    aget "/modules" do
        prep_session
        fill_component_cache{
            body show :modules, true
        }
    end

    #
    # sets modules
    #
    post "/modules" do
        session['opts']['modules'] = prep_modules( escape_hash( params ) )
        flash.now[:ok] = "Modules updated."
        show :modules, true
    end

    aget "/plugins" do
        prep_session
        fill_component_cache {
            body erb :plugins, { :layout => true },
                :session_options => YAML::load( session['opts']['plugins'] )
        }
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

    aget "/instance/:url" do |url|
        params['url'] = url
        instances.connect( params[:url], session ).framework.paused? {
            |paused|

            if !paused.rpc_connection_error?
                body erb :instance, { :layout => true }, :paused => paused,
                    :shutdown => false, :params => params
            else
                msg = "Instance at #{url} has been shutdown."
                body erb :instance, { :layout => true }, :shutdown => true,
                    :flash => { :notice => msg }
            end

        }

    end

    aget "/instance/:url/output.json" do |url|
        content_type :json

        params['url'] = url

        output = {
            'messages' => {},
            'issues'   => {},
            'stats'    => {}
        }

        instances.connect( params[:url], session ).framework.progress_data {
            |prog|

            if !prog.rpc_connection_error?

                @@output_streams ||= {}
                @@output_streams[params[:url]] = OutputStream.new( prog['messages'], 38 )
                output['messages'] = { 'data' => @@output_streams[params[:url]].format }
                output['issues'] = { 'data' => erb( :output_results, { :layout => false }, :issues => prog['issues'] ) }

                output['stats'] = prog['stats'].dup

                output['stats']['current_pages'] = []
                if prog['stats']['current_pages']
                    prog['stats']['current_pages'].each {
                        |url|
                        output['stats']['current_pages'] << escape( url )
                    }
                end

                output['stats']['instances'] = prog['instances'].dup
                body output.to_json
            else
                output['messages'] = { 'status' => 'finished', 'data' => "The server has been shut down." }
                body output.to_json
            end
        }
    end


    apost "/*/:url/pause" do |splat, url|
        params['splat'] = [ splat ]
        params['url']   = url

        redir = '/' + splat + ( splat == 'instance' ? "/#{url}" : '' )
        instances.connect( params[:url], session ).framework.pause!{
            |paused|
            if !paused.rpc_connection_error?
                log.instance_paused( env, params[:url] )
                msg = "Instance at #{params[:url]} will pause as soon as the current page is audited."
                async_redirect redir, :flash => { :notice => msg }
            else
                msg = "Instance at #{params[:url]} has been shutdown."
                async_redirect redir, :flash => { :notice => msg }
            end
        }
    end

    apost "/*/:url/resume" do |splat, url|
        params['splat'] = [ splat ]
        params['url']   = url

        redir = '/' + splat + ( splat == 'instance' ? "/#{url}" : '' )
        instances.connect( params[:url], session ).framework.resume!{
            |res|

            if !res.rpc_connection_error?
                log.instance_resumed( env, params[:url] )

                msg = "Instance at #{params[:url]} resumes."
                async_redirect redir, :flash => { :notice => msg }
            else
                msg = "Instance at #{params[:url]} has been shutdown."
                async_redirect redir, :flash => { :notice => msg }
            end
        }
    end

    apost "/*/:url/shutdown" do |splat, url|
        params['splat'] = [ splat ]
        params['url']   = url

        redir = '/' + ( splat == 'instance' ? "reports" : splat )
        save_and_shutdown( instances.connect( params[:url], session ) ){
            |res|

            log.instance_shutdown( env, params[:url] ) if !res.rpc_connection_error?

            msg = "Instance at #{params[:url]} has been shutdown."
            async_redirect redir, :flash => { :notice => msg }
        }

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
         :server => %w[ thin ]
         # :webrick => prep_webrick

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
