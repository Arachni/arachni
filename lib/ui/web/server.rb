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
require Arachni::Options.instance.dir['lib'] + 'rpc/xml/client/dispatcher'
require Arachni::Options.instance.dir['lib'] + 'rpc/xml/client/instance'
require Arachni::Options.instance.dir['lib'] + 'ui/web/report_manager'
require Arachni::Options.instance.dir['lib'] + 'ui/web/log'
require Arachni::Options.instance.dir['lib'] + 'ui/web/output_stream'

#
#
# Provides a web user interface for the Arachni Framework using Sinatra.<br/>
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1-pre
#
# @see Arachni::RPC::XML::Client::Instance
# @see Arachni::RPC::XML::Client::Dispatcher
#
module Web

    VERSION = '0.1.1-pre'

class Server < Sinatra::Base

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

        def report_count
            settings.reports.all.size
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

        def escape( str )
            CGI.escapeHTML( str )
        end

        def unescape( str )
            CGI.unescapeHTML( str )
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
            (rss.to_i * 4096 / 1024 / 1024).to_s + 'MB'
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

    set :log,     Log.new( Arachni::Options.instance, settings )
    set :reports, ReportManager.new( Arachni::Options.instance, settings )

    enable :sessions

    configure do
        # shit's on!
        settings.log.webui_started
    end

    def exception_jail( &block )
        # begin
            block.call
        # rescue Errno::ECONNREFUSED => e
        #     erb :error, { :layout => true }, :error => 'Remote server has been shut down.'
        # end
    end

    def show( page, layout = true )
        if page == :dispatcher
            ensure_dispatcher
            erb :dispatcher, { :layout => true }, :stats => dispatcher_stats
        else
            erb page.to_sym, { :layout => layout }
        end
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

    #
    # Provides an easy way to connect to an instance by port
    #
    # @param    [Integer]   port
    #
    def connect_to_instance( port )
        prep_session

        begin
            return Arachni::RPC::XML::Client::Instance.new( options, port_to_url( port ) )
        rescue Exception
            raise "Instance on port #{port} has shutdown."
        end
    end

    #
    # Converts a port to a URL instance.
    #
    # @param    [Integer]   port
    #
    def port_to_url( port )
        uri = URI( session[:dispatcher_url] )
        uri.port = port.to_i
        uri.to_s
    end

    #
    # Provides easy access to the dispatcher and handles failure
    #
    def dispatcher
        begin
            @dispatcher ||= Arachni::RPC::XML::Client::Dispatcher.new( options, session[:dispatcher_url] )
        rescue Exception => e
            redirect '/dispatcher_error'
        end
    end

    #
    # Provides statistics about running jobs etc using the dispatcher
    #
    def dispatcher_stats
        stats = dispatcher.stats
        stats['running_jobs'].each {
            |job|
            begin
                job['paused'] = connect_to_instance( job['port'] ).framework.paused?
            rescue
            end
        }
        return stats
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

    def escape_hash( hash )
        hash.each_pair {
            |k, v|
            hash[k] = escape( hash[k] ) if hash[k].is_a?( String )
            hash[k] = escape_hash( v ) if v.is_a? Hash
        }

        return hash
    end

    def unescape_hash( hash )
        hash.each_pair {
            |k, v|
            hash[k] = unescape( hash[k] ) if hash[k].is_a?( String )
            hash[k] = unescape_hash( v ) if v.is_a? Hash
        }

        return hash
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
                instance = dispatcher.dispatch( HELPER_OWNER )
                @@arachni = connect_to_instance( instance['port'] )
            end
            return @@arachni
        rescue
            redirect '/dispatcher/error'
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
        session[:dispatcher_url] ||= 'http://localhost:7331'

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
        begin
            dispatcher.alive?
        rescue Exception => e
            redirect '/dispatcher/error'
        end
    end

    #
    # Saves the report, shuts down the instance and returns the content as HTML
    # to be sent back to the user's browser.
    #
    # @param    [Arachni::RPC::XML::Client::Instance]   arachni
    #
    def save_shutdown_and_show( arachni )
        report = save_and_shutdown( arachni )
        settings.reports.get( 'html', settings.reports.all.last.id )
    end

    #
    # Saves the report and shuts down the instance
    #
    # @param    [Arachni::RPC::XML::Client::Instance]   arachni
    #
    def save_and_shutdown( arachni )
        arachni.framework.clean_up!( true )
        report_path = settings.reports.save( arachni.framework.auditstore )
        arachni.service.shutdown!
        return report_path
    end

    #
    # Kills all running instances
    #
    def shutdown_all
        settings.log.dispatcher_global_shutdown( env )
        dispatcher.stats['running_jobs'].each {
            |job|
            begin
                save_and_shutdown( connect_to_instance( job['port'] ) )
            rescue
                begin
                    connect_to_instance( job['port'] ).service.shutdown!
                rescue
                    settings.log.instance_fucker_wont_die( env, port_to_url( job['port'] ) )
                    next
                end
            end

            settings.log.instance_shutdown( env, port_to_url( job['port'] ) )
        }
    end

    #
    # Kills all idle instances
    #
    # @return    [Integer]  the number of reaped instances
    #
    def shutdown_zombies
        i = 0
        dispatcher.stats['running_jobs'].each {
            |job|

            begin
                arachni = connect_to_instance( job['port'] )

                begin
                    if !arachni.framework.busy? && !job['owner'] != HELPER_OWNER
                        save_and_shutdown( arachni )
                        settings.log.webui_zombie_cleanup( env, port_to_url( job['port'] ) )
                        i+=1
                    end
                rescue

                end

            rescue
            end
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

    get "/dispatcher" do
        show :dispatcher
    end

    #
    # sets the dispatcher URL
    #
    post "/dispatcher" do

        if !params['url'] || params['url'].empty?
            flash[:err] = "URL cannot be empty."
            show :dispatcher_error
        else

            session[:dispatcher_url] = params['url']
            settings.log.dispatcher_selected( env, params['url'] )
            begin
                dispatcher.jobs
                settings.log.dispatcher_verified( env, params['url'] )
                redirect '/'
            rescue
                settings.log.dispatcher_error( env, params['url'] )
                flash[:err] = "Couldn't find a dispatcher at \"#{escape( params['url'] )}\"."
                show :dispatcher_error
            end
        end
    end

    #
    # shuts down all instances
    #
    post "/dispatcher/shutdown" do
        shutdown_all
        redirect '/dispatcher'
    end


    get '/dispatcher/error' do
        show :dispatcher_error
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
        else

            instance = dispatcher.dispatch( params['url'] )
            settings.log.instance_dispatched( env, port_to_url( instance['port'] ) )
            settings.log.instance_owner_assigned( env, params['url'] )

            arachni  = connect_to_instance( instance['port'] )

            session['opts']['settings']['url'] = params['url']

            unescape_hash( session['opts'] )

            session['opts']['settings']['audit_links']   = true if session['opts']['settings']['audit_links']
            session['opts']['settings']['audit_forms']   = true if session['opts']['settings']['audit_forms']
            session['opts']['settings']['audit_cookies'] = true if session['opts']['settings']['audit_cookies']
            session['opts']['settings']['audit_headers'] = true if session['opts']['settings']['audit_headers']

            opts = prep_opts( session['opts']['settings'] )
            arachni.opts.set( opts )
            arachni.modules.load( session['opts']['modules'] )
            arachni.plugins.load( YAML::load( session['opts']['plugins'] ) )
            arachni.framework.run

            settings.log.scan_started( env, params['url'] )

            redirect '/instance/' + instance['port'].to_s
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

    get "/instance/:port" do
        begin
            arachni = connect_to_instance( params[:port] )
            erb :instance, { :layout => true }, :paused => arachni.framework.paused?, :shutdown => false
        rescue
            flash.now[:notice] = "Instance on port #{params[:port]} has been shutdown."
            erb :instance, { :layout => true }, :shutdown => true, :stats => dispatcher_stats
        end

    end

    get "/instance/:port/output.json" do
        content_type :json

        begin
            arachni = connect_to_instance( params[:port] )
            if arachni.framework.busy?
                { 'data' => OutputStream.new( arachni, 38 ).data }.to_json
            else
                settings.log.instance_shutdown( env, port_to_url( params[:port] ) )
                save_and_shutdown( arachni )

                # {
                #     'report' => '"data:text/html;base64, ' +
                #         Base64.encode64( save_shutdown_and_show( arachni ) ) + '"'
                # }.to_json

                { 'status' => 'finished', 'data' => "The server has been shut down." }.to_json
            end
        rescue
            { 'status' => 'finished', 'data' => "The server has been shut down." }.to_json
        end
    end

    get "/instance/:port/output_results.json" do
        content_type :json
        begin
            arachni = connect_to_instance( params[:port] )
            if !arachni.framework.paused? && arachni.framework.busy?
                out = erb( :output_results, { :layout => false }, :issues => YAML.load( arachni.framework.auditstore ).issues)
                { 'data' => out }.to_json
            end
        rescue
            { 'data' => "The server has been shut down." }.to_json
        end
    end

    get "/instance/:port/stats.json" do
        content_type :json
        begin
            arachni = connect_to_instance( params[:port] )
            stats = arachni.framework.stats
            stats['current_page'] = escape( stats['current_page'] )
            { 'refresh' => true, 'stats' => stats }.to_json
        rescue
            { 'refresh' => false }.to_json
        end
    end


    post "/*/:port/pause" do
        arachni = connect_to_instance( params[:port] )

        begin
            arachni.framework.pause!
            settings.log.instance_paused( env, port_to_url( params[:port] ) )

            flash.now[:notice] = "Instance on port #{params[:port]} will pause as soon as the current page is audited."
            erb params[:splat][0].to_sym, { :layout => true }, :paused => arachni.framework.paused?, :shutdown => false, :stats => dispatcher_stats
        rescue
            flash.now[:notice] = "Instance on port #{params[:port]} has been shutdown."
            erb params[:splat][0].to_sym, { :layout => true }, :shutdown => true, :stats => dispatcher_stats
        end

    end

    post "/*/:port/resume" do
        arachni = connect_to_instance( params[:port] )

        begin
            arachni.framework.resume!
            settings.log.instance_resumed( env, port_to_url( params[:port] ) )

            flash.now[:notice] = "Instance on port #{params[:port]} resumes."
            erb params[:splat][0].to_sym, { :layout => true }, :paused => arachni.framework.paused?, :shutdown => false, :stats => dispatcher_stats
        rescue
            flash.now[:notice] = "Instance on port #{params[:port]} has been shutdown."
            erb params[:splat][0].to_sym, { :layout => true }, :shutdown => true, :stats => dispatcher_stats
        end
    end

    post "/*/:port/shutdown" do
        arachni = connect_to_instance( params[:port] )

        begin
            arachni.framework.busy?
            settings.log.instance_shutdown( env, port_to_url( params[:port] ) )

            begin
                save_shutdown_and_show( arachni )
            rescue
                flash.now[:notice] = "Instance on port #{params[:port]} has been shutdown."
                show params[:splat][0].to_sym
            ensure
                arachni.service.shutdown!
            end
        rescue
            flash.now[:notice] = "Instance on port #{params[:port]} has already been shutdown."
            erb params[:splat][0].to_sym, { :layout => true }, :shutdown => true, :stats => dispatcher_stats
        end
    end

    get "/reports" do
        erb :reports, { :layout => true }, :reports => settings.reports.all( :order => :datestamp.desc ),
            :available => settings.reports.available
    end

    get '/reports/formats' do
        erb :report_formats, { :layout => true }, :reports => settings.reports.available
    end

    post '/reports/delete' do
        settings.reports.delete_all
        settings.log.reports_deleted( env )

        redirect '/reports'
    end

    post '/report/:id/delete' do
        settings.reports.delete( params[:id] )
        settings.log.report_deleted( env, params[:id] )

        redirect '/reports'
    end

    get '/report/:id.:type' do
        settings.log.report_converted( env, params[:id] + '.' + params[:type] )
        content_type( params[:type], :default => 'application/octet-stream' )
        settings.reports.get( params[:type], params[:id] )
    end

    get '/log' do
        erb :log, { :layout => true }, :entries => settings.log.entry.all.reverse
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

        settings.log.webui_shutdown

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
