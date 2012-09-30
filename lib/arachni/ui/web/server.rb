=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

require 'data_mapper'
require 'eventmachine'
require 'em-synchrony'
require 'sinatra/async'
require 'sinatra/flash'
require 'securerandom'
require 'json'
require 'erb'
require 'cgi'
require 'fileutils'

#
# Monkey patch Sinatra::Async to support error handling.
#
# This is from their own repo, can't wait for them to push the gem though.
#
module Sinatra::Async
    def aerror( &block )
        define_method :aerror, &block
    end

    module Helpers
        def async_handle_exception
            yield
        rescue ::Exception => boom
            if respond_to? :aerror
                aerror boom
            elsif settings.show_exceptions?
                printer = Sinatra::ShowExceptions.new( proc{ raise boom } )
                s, h, b = printer.call( request.env )
                response.status = s
                response.headers.replace( h )
                response.body = b
            else
                body( handle_exception!( boom ) )
            end
        end
    end
end

#
# Monkey patch Rack's cookie management to fix a nil error
#
# @see https://github.com/rack/rack/pull/304
#
class Rack::Session::Cookie
    def unpacked_cookie_data(env)
        env["rack.session.unpacked_cookie_data"] ||= begin
            request = Rack::Request.new(env)
            session_data = request.cookies[@key]

            if @secret && session_data
                session_data, digest = session_data.split("--")
                unless digest == generate_hmac(session_data, @secret)
                    # Clear the session data if secret doesn't match and old secret doesn't match
                    session_data = nil if (@old_secret.nil? || (digest != generate_hmac(session_data, @old_secret)))
                end
            end

            coder.decode(session_data) || {}
        end
    end
end

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
# It's basically an RPC client for Dispatchers and Instances wearing a pretty frock.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @see Arachni::RPC::Client::Instance
# @see Arachni::RPC::Client::Dispatcher
#
module Web

    VERSION = '0.3.0.1'

class Server < Sinatra::Base

    register Sinatra::Flash
    register Sinatra::Async

    include Arachni::Utilities
    include Utilities

    configure do
        use Rack::Session::Cookie

        opts = Arachni::Options.instance

        if opts.webui_username && opts.webui_password
            use Rack::Auth::Basic, "Arachni WebUI v" + Arachni::UI::Web::VERSION + " requires authentication." do |username, password|
                [username, password] == [ opts.webui_username, opts.webui_password ]
            end
        end

        @@conf = YAML::load_file( opts.dir['conf'] + 'webui.yaml' )
        opts.ssl      = @@conf['ssl']['client']['enable']
        opts.ssl_pkey = @@conf['ssl']['client']['key']
        opts.ssl_cert = @@conf['ssl']['client']['cert']
        opts.ssl_ca   = @@conf['ssl']['client']['ca']
    end

    helpers do

        #
        # Converts seconds to a (00:00:00) (hours:minutes:seconds) string
        #
        # @param    [String,Float,Integer]    secs
        #
        # @return    [String]     hours:minutes:seconds
        #
        def secs_to_hms( secs )
            secs = secs.to_i
            return [secs/3600, secs/60 % 60, secs % 60].map {
                |t|
                t.to_s.rjust( 2, '0' )
            }.join(':')
        end

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
            return if !rules || !rules.is_a?( Hash ) || rules.empty?

            str = ''
            rules.each {
                |regexp, counter|
                next if !regexp || !counter
                str += regexp.to_s + ':' + counter.to_s + "\r\n"
            }
            return str
        end

        def format_custom_headers( headers )
            return if !headers || !headers.is_a?( Hash ) || headers.empty?

            str = ''
            headers.each_pair {
                |name, val|
                str += "#{name}=#{val}\r\n"
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
            # Rack::Csrf.csrf_token( env )
            @@csrf_token ||= SecureRandom.base64( 32 )
        end

        def csrf_field
            '_csrf'
        end

        def csrf_key
            'csrf.token'
        end

        def csrf_tag
            # Rack::Csrf.csrf_tag( env )
            %Q(<input type="hidden" name="#{csrf_field}" value="#{csrf_token}" />)
        end

        def modules
            @@modules
        end

        def plugins
            @@plugins.reverse
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
    set :public_folder, "#{dir}/server/public"
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
    set :conf,       @@conf
    set :addons,     AddonManager.new( Arachni::Options.instance, settings )

    configure do
        # shit's on!
        log.webui_started
    end

    def async_redirect( location, opts = {} )
        response.status = 302

        if methods.include?( :current_addon ) && current_addon &&
            location != '/dispatchers/edit'
            location = current_addon.path_root + location
        end

        if ( flash = opts[:flash] ) && !flash.empty?
            location += "?#{flash.keys[0]}=#{URI.encode( flash.values[0] )}"
        end

        response.headers['Location'] = location

        body ''
    end

    def redirect( location, opts = {} )
        if methods.include?( :current_addon ) && current_addon
            location = current_addon.path_root + location
        end

        if ( flash = opts[:flash] ) && !flash.empty?
            location += "?#{flash.keys[0]}=#{URI.encode( flash.values[0] )}"
        end

        super( location )
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

        rss = 0
        mem = 0
        cpu = 0

        stats['running_jobs'].each {
            |job|
            rss += proc_mem( job['proc']['rss'] ).to_i
            mem += Float( job['proc']['pctmem'] ) if job['proc']['pctmem']
            cpu += Float( job['proc']['pctcpu'] ) if job['proc']['pctcpu']
        }
        str += rss.to_s + 'MB RAM usage '
        str += '(' + mem.to_s[0..4] + '%), '
        str += cpu.to_s[0..4] + '% CPU usage'
    end

    def show_dispatcher_node_line( stats )
        str = "Nickname: #{stats['node']['nickname']} - "
        str += "Pipe ID: #{stats['node']['pipe_id']} - "
        str += "Weight: #{stats['node']['weight']}"
    end

    def welcomed?
        File.exist?( settings.db + '/welcomed' )
    end

    def welcomed!
        File.new( settings.db + '/welcomed', 'w' ).close
    end

    def ensure_welcomed
        return if welcomed?
        async_redirect '/welcome'
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
    # Prepares form params to be used as options for RPC transmission
    #
    # @param    [Hash]  params
    #
    # @return   [Hash]  normalized hash
    #
    def prep_opts( params )
        need_to_split = %w(exclude_cookies exclude_vectors exclude include)

        cparams = {}
        params.each_pair {
            |name, value|

            next if %w(_csrf modules plugins).include?( name ) || ( value.is_a?( String ) && value.empty?)

            value = true if value == 'on'

            if name == 'cookiejar' && value[:tempfile]
                cparams['cookies'] = {}
                cparams['cookie_string'] = ''
                Arachni::Element::Cookie.from_file( '', value[:tempfile] ).each do |c|
                    cparams['cookies'][c.name] = c.value
                    cparams['cookie_string'] += c.to_s + ';'
                end
            elsif name == 'extend_paths' && !value.is_a?( Array ) && value[:tempfile]
               cparams['extend_paths'] = Arachni::Options.instance.paths_from_file( value[:tempfile] )
            elsif name == 'restrict_paths' && !value.is_a?( Array ) && value[:tempfile]
               cparams['restrict_paths'] = Arachni::Options.instance.paths_from_file( value[:tempfile] )
            elsif need_to_split.include?( name ) && value.is_a?( String )
                cparams[name] = value.split( "\r\n" )

            elsif name == 'redundant' && value.is_a?( String )
                cparams[name] = {}
                value.split( "\r\n" ).each {
                    |rule|
                    regexp, counter = rule.split( ':', 2 )
                    cparams[name][regexp] = counter
                }
            elsif name == 'custom_headers' && value.is_a?( String )
                cparams[name] = {}
                value.split( "\r\n" ).each {
                    |line|
                    header, val = line.to_s.split( /=/, 2 )
                    cparams[name][header] = val
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

        dispatchers.first_alive {
            |dispatcher|
            if !dispatcher
                async_redirect '/dispatchers/edit'
            else
                dispatchers.connect( dispatcher.url ).dispatch( HELPER_OWNER ){
                    |instance|

                    if instance.rpc_exception?
                        log.webui_helper_instance_connect_failed( env, url )
                        next
                    end

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

            helper_instance {
                |inst|

                if !inst
                    block.call
                else

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
                end
            }

        else
            block.call
        end
    end

    #
    # Makes sure that all systems are go and populates the session with default values
    #
    def prep_session( skip_dispatcher = false )
        session[:flash] ||= {}

        ensure_dispatcher if !skip_dispatcher

        session['opts'] ||= {}
        session['opts']['settings'] ||= {
            'audit_links'    => true,
            'audit_forms'    => true,
            'audit_cookies'  => true,
            'http_req_limit' => 20,
            'user_agent'     => 'Arachni/' + Arachni::VERSION
        }
        session['opts']['modules'] ||= [ '*' ]


        require Arachni::Options.instance.dir['lib'] + 'framework'
        framework = Arachni::Framework.new( Arachni::Options.instance )
        plugins = Arachni::Plugin::Manager.new( framework )

        default_plugins = {}
        plugins.parse( Arachni::Plugin::Manager::DEFAULT ).each {
            |mod|
            default_plugins[mod] = {}
        }

        session['opts']['plugins'] ||= YAML::dump( default_plugins )

        #
        # Garbage collector, zombie killer. Reaps idle processes every 60 seconds.
        #
        @@zombie_reaper ||=
            ::EM.add_periodic_timer( 60 ){ ::EM.defer { shutdown_zombies } }
    end

    #
    # Makes sure that we have a dispatcher, if not it redirects the user to
    # an appropriate error page.
    #
    # @return   [Bool]  true if alive, redirect if not
    #
    def ensure_dispatcher
        if dispatchers.all.empty?
            async_redirect '/dispatchers/edit'
        else
            dispatchers.first_alive {
                |dispatcher|
                async_redirect '/dispatchers/edit' if !dispatcher
            }
        end
    end

    #
    # Saves the report and shuts down the instance
    #
    # @param    [String]   url  of the instance
    #
    def save_and_shutdown( url, &block )
        instance = instances.connect( url, session )
        instance.framework.clean_up{
            |res|

            if !res.rpc_connection_error?
                instance.framework.auditstore {
                    |auditstore|

                    if !auditstore.rpc_connection_error?
                        log.webui_save_and_shutdown_auditstore_success( env, url )
                        report_path = reports.save( auditstore )
                        instance.service.shutdown!{ block.call( report_path ) }
                    else
                        log.webui_save_and_shutdown_auditstore_failed( env, url )
                        block.call( auditstore )
                    end
                }
            else
                log.webui_save_and_shutdown_clean_up_failed( env, url )
                block.call( res )
            end
        }
    end

    #
    # Kills all running instances
    #
    def shutdown_all( url, &block )
        dispatchers.connect( url ).stats {
            |stats|
            log.dispatcher_global_shutdown( env, url )

            stats['running_jobs'].each {
                |instance|

                next if instance['helpers']['rank'] == 'slave'

                save_and_shutdown( instance['url'] ){
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

                instances.connect( job['url'], session ).framework.busy? {
                    |busy|

                    if !busy.rpc_exception? && !busy
                        save_and_shutdown( job['url'] ){
                            log.webui_zombie_cleanup( env, job['url'] )
                        }
                    end
                }
            }
        }
    end

    def show_error( title, message = '', backtrace = [] )
        skip = [
            'rack.input',
            'rack.errors',
            'async.callback',
            'async.close',
            'rack.logger',
        ]

        err_env = {}
        env.each {
            |k, v|
            next if skip.include?( k )
            err_env[k] = v
        }

        err_env['rack.session.options'].delete( :coder )
        err_env['rack.session.options'].delete( :secure_random )

        err_env.merge!(
            :title     => title,
            :message   => message,
            :backtrace => backtrace.join( "\n" )
        )

        erb :error, { :layout => true },
            :title     => escape( title ),
            :message   => escape( message ).gsub( "\n", '<br />' ),
            :backtrace => escape( backtrace.join( "\n" ) ),
            :env       => escape( err_env.to_yaml )
    end

    not_found do
        show_error( 'Could not find the requested path',
            'Please use the menus for navigation, it\'ll be easier on you...' )
    end

    before do
        if %q{POST PUT DELETE}.include?( env['REQUEST_METHOD'] ) &&
            csrf_token != params[csrf_field]
            redirect '/csrf_error'
        end
    end

    aerror do |e|
        body show_error( e.class.to_s, e.message, e.backtrace )
    end

    aget '/csrf_error' do
        body show_error( 'Invalid CSRF token',
            "The CSRF token that accompanied your last request was invalid.\n" +
            "Please go back and try again..."
        )
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
        welcomed!
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
                json = { 'log' => escape( log ) }.to_json
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
            msg = 'All instances will be shut down shortly, the reports will be download and saved automatically.'
            async_redirect '/dispatchers', :flash => { :notice => msg }
        }
    end

    #
    # starts a scan
    #
    apost "/scan" do
        prep_session( true )

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
        else

            session['opts']['settings']['url'] = params[:url]

            unescape_hash( session['opts'] )
            session['opts']['settings']['audit_links']   = true if session['opts']['settings']['audit_links']
            session['opts']['settings']['audit_forms']   = true if session['opts']['settings']['audit_forms']
            session['opts']['settings']['audit_cookies'] = true if session['opts']['settings']['audit_cookies']
            session['opts']['settings']['audit_headers'] = true if session['opts']['settings']['audit_headers']

            opts = {}
            opts['settings'] = prep_opts( session['opts']['settings'] )
            opts['settings'] = session['opts']['settings']

            if params['high_performance']
                opts['settings']['grid_mode'] = 'high_performance'
                opts['settings']['min_pages_per_instance']=
                    params['min_pages_per_instance']

                opts['settings']['max_slaves'] = params['max_slaves']
            end

            opts['plugins']  = YAML::load( session['opts']['plugins'] )
            opts['modules']  = session['opts']['modules']

            job = Scheduler::Job.new(
                :dispatcher  => params[:dispatcher],
                :url         => params[:url],
                :opts        => YAML.dump( opts ),
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
        prep_session
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
        prep_session
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

            params = aparams
            if !prog.rpc_exception?

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
            else
                msg = "The instance has been shutdown."
                output['messages'] = { 'data' => msg }
                output['issues']   = { 'data' => msg }
                output['status']   = 'finished'
            end
            body output.to_json
        }
    end


    apost "/*/:url/pause" do |splat, url|
        params['splat'] = [ splat ]
        params['url']   = url

        redir = '/' + splat + ( splat == 'instance' ? "/#{url}" : '' )
        instances.connect( params[:url], session ).framework.pause{
            |paused|

            params = aparams
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
        instances.connect( params[:url], session ).framework.resume{
            |res|

            params = aparams
            if !res.rpc_connection_error?
                log.instance_resumed( env, params[:url] )

                msg = "Instance at #{params[:url]} resumes."
                async_redirect redir, :flash => { :ok => msg }
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
        save_and_shutdown( params[:url] ){
            |res|

            params = aparams
            if !res.rpc_connection_error?
                log.instance_shutdown( env, params[:url] )
                msg = {
                     :ok => "Instance at #{params[:url]} has been shutdown."
                 }
            else
                redir = '/' + ( splat == 'instance' ? splat + '/' + url : splat )
                msg = {
                    :err => "Instance at #{params[:url]} could not be shutdown at the moment."
                 }
            end

            async_redirect redir, :flash => { msg.keys[0] => msg.values[0] }
        }

    end

    aget "/instance/*:*" do
        params['url'] = params[:url] = params[:splat].first + ':' + params[:splat].last
        instances.connect( params[:url], session ).framework.paused? {
            |paused|

            params = aparams
            if !paused.rpc_connection_error?
                body erb :instance, { :layout => true }, :paused => paused,
                    :shutdown => false, :params => params
            else
                msg = "Instance at #{params[:url]} has been shutdown."
                body erb :instance, { :layout => true }, :shutdown => true,
                    :flash => { :notice => msg }
            end
        }

    end

    aget "/reports" do
        body erb :reports, { :layout => true }, :reports => reports.all( :order => :datestamp.desc ),
            :available => reports.available
    end

    aget '/reports/formats' do
        body erb :report_formats, { :layout => true }, :reports => reports.available
    end

    apost '/reports/delete' do
        reports.delete_all
        log.reports_deleted( env )

        async_redirect '/reports'
    end

    apost '/report/:id/delete' do |id|
        reports.delete( id )
        log.report_deleted( env, id )

        async_redirect '/reports'
    end

    aget '/report/:id.:type' do |id, type|
        log.report_converted( env, id + '.' + type )
        content_type( type, :default => 'application/octet-stream' )
        body reports.get( type, id )
    end

    aget '/log' do
        body erb :log, { :layout => true }, :entries => log.entry.all.reverse
    end

    aget '/addons' do
        body erb :addons
    end

    apost '/addons' do
        params['addons'] ||= {}
        addon_names = params['addons'].keys

        addons.enable!( addon_names )
        body erb :addons
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

        handler.run self, handler_opts.merge( :Host => options[:host], :Port => options[:port] ) do
            |server|
            [ :INT, :TERM ].each { |sig| trap( sig ) { quit!( server, handler_name ) } }

            set :running, true
        end
    rescue Errno::EADDRINUSE => e
        puts "== Someone is already performing on port #{port}!"
    end

    def self.prep_thin
        if @@conf['ssl']['server']['key']
            pkey = ::OpenSSL::PKey::RSA.new( File.read( @@conf['ssl']['server']['key'] ) )
        end

        if @@conf['ssl']['server']['cert']
            cert = ::OpenSSL::X509::Certificate.new( File.read( @@conf['ssl']['server']['cert'] ) )
        end

        if @@conf['ssl']['key'] || @@conf['ssl']['cert'] || @@conf['ssl']['ca']
            verification = true
        end

        return {
            :ssl        => true,
            :ssl_verify => verification,
            :ssl_cert_file  => cert,
            :ssl_key_file   => pkey,
        }
    end

    run! :host    => Arachni::Options.instance.server || '0.0.0.0',
         :port    => Arachni::Options.instance.rpc_port || 4567,
         :server  => %w[ thin ],
         :thin    => prep_thin

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
