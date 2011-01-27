require 'sinatra/base'
require "rack/csrf"
require 'rack-flash'
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

module Web

    VERSION = '0.1-pre'

class Server < Sinatra::Base

    class OutputStream

        def initialize( output )
            @output  = output
        end

        def each

            icon_whitelist = {}

            [ 'status', 'ok', 'error', 'info' ].each {
                |icon|
                icon_whitelist[icon] = "<img src='/icons/#{icon}.png' />"
            }

            yield '<link rel="stylesheet" href="/style.css" type="text/css" />'
            yield "<pre>"
            @output << { 'refresh' => '<meta http-equiv="refresh" content="1">' }
            @output.each {
                |out|

                type = out.keys[0]
                msg  = out.values[0]

                next if out.values[0].empty?

                icon = icon_whitelist[type] || ''

                if out.keys[0] != 'refresh'
                    yield icon + CGI.escapeHTML( " #{out.values[0]}" ) + "</br>"
                else
                    yield out.values[0]
                end
            }
        end

    end

    use Rack::Flash

    configure do
        use Rack::Session::Cookie
        use Rack::Csrf, :raise => true
    end

    helpers do

        def escape( str )
            CGI.escapeHTML( str )
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

        def helper_instance
            begin
                @@arachni ||= nil
                if !@@arachni
                    instance = dispatcher.dispatch( 'Web Interface [Do *not* kill]' )
                    @@arachni = connect_to_instance( instance['port'] )
                end
                return @@arachni
            rescue
                redirect '/dispatcher/error'
            end
        end

        def modules
            @@modules ||= helper_instance.framework.lsmod.dup
        end

        def plugins
            @@plugins ||= helper_instance.framework.lsplug.dup
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
    set :static, true
    set :environment, :development

    enable :sessions

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
            erb :dispatcher, { :layout => true }, :stats => dispatcher.stats
        else
            erb page.to_sym,  { :layout => layout }
        end
    end

    def connect_to_instance( port )
        prep_session

        uri = URI( session[:dispatcher_url] )
        uri.port = port.to_i
        begin
            return Arachni::RPC::XML::Client::Instance.new( options, uri.to_s )
        rescue Exception
            raise "Instance on port #{port} has shutdown."
        end
    end

    def dispatcher
        begin
            @dispatcher ||= Arachni::RPC::XML::Client::Dispatcher.new( options, session[:dispatcher_url] )
        rescue Exception
            show :dispatcher_error
        end
    end

    def options
        Arachni::Options.instance
    end

    def to_i( str )
        return str if !str.is_a?( String )

        if str.match( /\d+/ ).to_s.size == str.size
            return str.to_i
        else
            return str
        end
    end

    def prep_opts( params )

        cparams = {}
        params.each_pair {
            |name, value|

            next if [ '_csrf', 'modules', 'plugins' ].include?( name ) || ( value.is_a?( String ) && value.empty?)

            value = true if value == 'on'
            cparams[name] = to_i( value )
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
            'healthmap'     => {}
        } )
    end

    def handle_report( report )
        reports = ::Arachni::Report::Manager.new( ::Arachni::Options.instance )
        [ 'afr', 'html' ].each {
            |ext|
            reports.run_one( ext, report )

            file = Dir.glob( ::Arachni::Options.instance.dir['root'] + "*.#{ext}" ).last
            next if !file

            new_loc = settings.public + "/reports/#{ext}/" + File.basename( file )
            FileUtils.mv( file, new_loc )
        }
    end

    def get_reports( type )
        Dir.glob( settings.public + "/reports/#{type}/*.#{type}" )
    end

    def ensure_dispatcher
        begin
            dispatcher.alive?
        rescue
            redirect '/dispatcher/error'
        end
    end

    get "/" do
        prep_session
        show :home
    end

    get "/dispatcher" do
        show :dispatcher
    end

    post "/dispatcher" do

        if !params['url'] || params['url'].empty?
            flash[:err] = "URL cannot be empty."
            show :dispatcher_error
        else

            session[:dispatcher_url] = params['url']
            begin
                dispatcher.jobs
                redirect '/'
            rescue
                flash[:err] = "Couldn't find a dispatcher at \"#{escape( params['url'] )}\"."
                show :dispatcher_error
            end
        end
    end

    get '/dispatcher/error' do
        show :dispatcher_error
    end

    post "/scan" do

        if !params['url'] || params['url'].empty?
            flash[:err] = "URL cannot be empty."
            show :home

        else

            instance = dispatcher.dispatch( params['url'] )
            arachni  = connect_to_instance( instance['port'] )

            session['opts']['settings']['url'] = params['url']

            session['opts']['settings']['audit_links']   = true if session['opts']['settings']['audit_links']
            session['opts']['settings']['audit_forms']   = true if session['opts']['settings']['audit_forms']
            session['opts']['settings']['audit_cookies'] = true if session['opts']['settings']['audit_cookies']
            session['opts']['settings']['audit_headers'] = true if session['opts']['settings']['audit_headers']

            arachni.opts.set( prep_opts( session['opts']['settings'] ) )
            arachni.modules.load( session['opts']['modules'] )
            arachni.plugins.load( YAML::load( session['opts']['plugins'] ) )
            arachni.framework.run

            redirect '/instance/' + instance['port'].to_s
        end

    end

    get "/modules" do
        prep_session
        show :modules, true
    end

    post "/modules" do
        session['opts']['modules'] = prep_modules( params )
        flash.now[:notice] = "Modules updated."
        show :modules, true
    end

    get "/plugins" do
        prep_session
        erb :plugins, { :layout => true }
    end

    post "/plugins" do
        session['opts']['plugins'] = YAML::dump( prep_plugins( params ) )
        flash.now[:notice] = "Plugins updated."
        show :plugins, true
    end

    get "/settings" do
        prep_session
        erb :settings, { :layout => true }
    end

    post "/settings" do

        if session['opts']['settings']['url']
            url = session['opts']['settings']['url'].dup
            session['opts']['settings'] = prep_opts( params )
            session['opts']['settings']['url'] = url
        end

        flash.now[:notice] = "Settings updated."
        show :settings, true
    end

    get "/instance/:port" do
        show :instance, true
    end

    get "/instance/:port/output" do
        begin
            arachni = connect_to_instance( params[:port] )

            if arachni.framework.busy?
                OutputStream.new( arachni.service.output )
            else
                handle_report( YAML::load( arachni.framework.auditstore ) )
                arachni.service.shutdown!
                File.read( get_reports( 'html' ).last )
            end
        rescue Errno::ECONNREFUSED
            "The server has been shut down."
        end
    end

    post "/*/:port/pause" do
        connect_to_instance( params[:port] ).framework.pause!
        flash.now[:notice] = "Instance on port #{params[:port]} will pause as soon as the current page is audited."
        show params[:splat][0].to_sym
    end

    post "/*/:port/resume" do
        connect_to_instance( params[:port] ).framework.resume!
        flash.now[:ok] = "Instance on port #{params[:port]} resumes."
        show params[:splat][0].to_sym
    end

    post "/*/:port/shutdown" do
        arachni = connect_to_instance( params[:port] )

        # flash.now[:ok] = "Instance on port #{params[:port]} has been shutdown."

        handle_report( YAML::load( arachni.framework.auditstore ) )
        arachni.service.shutdown!
        File.read( get_reports( 'html' ).last )

        # show params[:splat][0].to_sym
    end

    get "/stats" do
        dispatcher.stats.to_s
    end

    run!

    at_exit do
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
