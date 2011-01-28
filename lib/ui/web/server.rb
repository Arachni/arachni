=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

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
require Arachni::Options.instance.dir['lib'] + 'ui/web/report_manager'
require Arachni::Options.instance.dir['lib'] + 'ui/web/log'


#
#
# Provides a web user interface for the Arachni Framework using Sinatra.<br/>
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1-pre
# @see Arachni::Framework
#
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
                    instance = dispatcher.dispatch( 'WebUI helper' )
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
    set :tmp,    "#{dir}/server/tmp"
    set :db,     "#{dir}/server/db"
    set :static, true
    set :environment, :development

    set :log,     Log.new( Arachni::Options.instance, settings )
    set :reports, ReportManager.new( Arachni::Options.instance, settings )

    enable :sessions

    configure do
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

    def connect_to_instance( port )
        prep_session

        begin
            return Arachni::RPC::XML::Client::Instance.new( options, port_to_url( port ) )
        rescue Exception
            raise "Instance on port #{port} has shutdown."
        end
    end

    def port_to_url( port )
        uri = URI( session[:dispatcher_url] )
        uri.port = port.to_i
        uri.to_s
    end

    def dispatcher
        begin
            @dispatcher ||= Arachni::RPC::XML::Client::Dispatcher.new( options, session[:dispatcher_url] )
        rescue Exception
            show :dispatcher_error
        end
    end

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

    def to_i( str )
        return str if !str.is_a?( String )

        if str.match( /\d+/ ).to_s.size == str.size
            return str.to_i
        else
            return str
        end
    end

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

    def ensure_dispatcher
        begin
            dispatcher.alive?
        rescue
            redirect '/dispatcher/error'
        end
    end

    def save_shutdown_and_show( arachni )
        report = settings.reports.save( arachni.framework.auditstore )
        arachni.service.shutdown!
        settings.reports.get( 'html', File.basename( report, '.afr' ) )
    end

    def save_and_shutdown( arachni )
        settings.reports.save( arachni.framework.auditstore )
        arachni.service.shutdown!
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

    post "/dispatcher/shutdown" do
        settings.log.dispatcher_global_shutdown( env )
        dispatcher.stats['running_jobs'].each {
            |job|
            begin
                save_and_shutdown( connect_to_instance( job['port'] ) )
            rescue
                connect_to_instance( job['port'] ).service.shutdown!
            end

            settings.log.instance_shutdown( env, port_to_url( job['port'] ) )
        }
        redirect '/dispatcher'
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
            settings.log.instance_dispatched( env, port_to_url( instance['port'] ) )
            settings.log.instance_owner_assigned( env, params['url'] )

            arachni  = connect_to_instance( instance['port'] )

            session['opts']['settings']['url'] = params['url']

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
        begin
            arachni = connect_to_instance( params[:port] )
            erb :instance, { :layout => true }, :paused => arachni.framework.paused?, :shutdown => false
        rescue
            flash.now[:notice] = "Instance on port #{params[:port]} has been shutdown."
            erb :instance, { :layout => true }, :shutdown => true, :stats => dispatcher_stats
        end

    end

    get "/instance/:port/output" do
        begin
            arachni = connect_to_instance( params[:port] )

            if arachni.framework.busy?
                OutputStream.new( arachni.service.output )
            else
                save_shutdown_and_show( arachni )
            end
        rescue Errno::ECONNREFUSED
            "The server has been shut down."
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

            flash.now[:ok] = "Instance on port #{params[:port]} resumes."
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
                flash.now[:ok] = "Instance on port #{params[:port]} has been shutdown."
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

        reports = []
        settings.reports.all.each {
            |report|
            name = File.basename( report, '.afr' )
            host, date = name.split( ':', 2 )
            reports << {
                'host'  => host,
                'date'  => date,
                'name'  => name
            }
        }

        erb :reports, { :layout => true }, :reports => reports,
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

    post '/report/:name/delete' do
        settings.reports.delete( params[:name] )
        settings.log.report_deleted( env, params[:name] )

        redirect '/reports'
    end

    get '/report/:name.:type' do
        settings.reports.get( params[:type], params[:name] )
        settings.log.report_converted( env, params[:name] )
    end

    get '/log' do
        erb :log, { :layout => true }, :entries => settings.log.entry.all.reverse
    end

    run!

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
