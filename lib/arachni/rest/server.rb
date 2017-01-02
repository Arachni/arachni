=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'puma'
require 'puma/minissl'
require 'sinatra'
require 'sinatra/contrib'

module Arachni
module Rest

class Server < Sinatra::Base
    lib = Options.paths.lib
    require lib + 'processes'
    require lib + 'rest/server/instance_helpers'

    helpers InstanceHelpers

    use Rack::Deflater
    use Rack::Session::Pool

    set :environment, :production

    enable :logging

    VALID_REPORT_FORMATS = %w(json xml yaml html.zip)

    before do
        protected!
        content_type :json
    end

    helpers do
        def protected!
            if !settings.respond_to?( :username )
                settings.set :username, nil
            end

            if !settings.respond_to?( :password )
                settings.set :password, nil
            end

            return if !settings.username && !settings.password
            return if authorized?

            headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
            halt 401, "Not authorized\n"
        end

        def authorized?
            @auth ||= Rack::Auth::Basic::Request.new( request.env )
            @auth.provided? && @auth.basic? && @auth.credentials == [
                settings.username.to_s, settings.password.to_s
            ]
        end

        def fail_if_not_exists
            token = params[:id]

            return if exists? token

            halt 404, "Scan not found for token: #{h token}."
        end

        def h( text )
            Rack::Utils.escape_html( text )
        end
    end

    # List scans.
    get '/scans' do
        json instances.keys.inject({}){ |h, k| h.merge! k => {}}
    end

    # Create
    post '/scans' do
        options = ::JSON.load( request.body.read ) || {}

        instance = Processes::Instances.spawn( fork: false )

        begin
            instance.service.scan( options )
        rescue => e
            Processes::Instances.kill( instance.url )
            halt 500,
                 json(
                     error:     "#{e.class}: #{e}",
                     backtrace: e.backtrace
                 )
        end

        instances[instance.token] = instance

        json id: instance.token
    end

    # Progress
    get '/scans/:id' do
        fail_if_not_exists

        session[params[:id]] ||= {
            seen_issues:  [],
            seen_errors:  0,
            seen_sitemap: 0
        }

        data = scan_for( params[:id] ).progress(
            with:    [
                :issues,
                errors:  session[params[:id]][:seen_errors],
                sitemap: session[params[:id]][:seen_sitemap]
            ],
            without: [
                issues: session[params[:id]][:seen_issues]
            ]
        )

        data[:issues].each do |issue|
            session[params[:id]][:seen_issues] << issue['digest']
        end

        session[params[:id]][:seen_errors]  += data[:errors].size
        session[params[:id]][:seen_sitemap] += data[:sitemap].size

        json data
    end

    get '/scans/:id/summary' do
        fail_if_not_exists

        json scan_for( params[:id] ).progress
    end

    get '/scans/:id/report.html.zip' do
        fail_if_not_exists
        content_type 'zip'
        scan_for( params[:id] ).report_as( 'html' )
    end

    get '/scans/:id/report.?:format?' do
        fail_if_not_exists

        params[:format] ||= 'json'

        if !VALID_REPORT_FORMATS.include?( params[:format] )
            halt 400, "Invalid report format: #{h params[:format]}."
        end

        content_type params[:format]

        scan_for( params[:id] ).report_as( params[:format] )
    end

    put '/scans/:id/pause' do
        fail_if_not_exists

        json scan_for( params[:id] ).pause
    end

    put '/scans/:id/resume' do
        fail_if_not_exists

        json scan_for( params[:id] ).resume
    end

    # Abort/shutdown
    delete '/scans/:id' do
        fail_if_not_exists
        id = params[:id]

        instance = instances[id]
        instance.service.shutdown

        # Make sure.
        kill_instance( id )

        instances.delete( id ).close

        session.delete params[:id]

        json nil
    end

    class <<self
        include Arachni::UI::Output

        def run!( options )
            set :username, options[:username]
            set :password, options[:password]

            server = Puma::Server.new( self )
            server.min_threads = 0
            server.max_threads = 16

            ssl = false
            if options[:ssl_key] && options[:ssl_certificate]
                ctx = Puma::MiniSSL::Context.new

                ctx.key  = options[:ssl_key]
                ctx.cert = options[:ssl_certificate]

                if options[:ssl_ca]
                    print_info 'CA provided, peer verification has been enabled.'

                    ctx.ca          = options[:ssl_ca]
                    ctx.verify_mode = Puma::MiniSSL::VERIFY_PEER |
                        Puma::MiniSSL::VERIFY_FAIL_IF_NO_PEER_CERT
                else
                    print_info 'CA missing, peer verification has been disabled.'
                end

                ssl = true
                server.binder.add_ssl_listener( options[:bind], options[:port], ctx )
            else
                ssl = false
                server.add_tcp_listener( options[:bind], options[:port] )
            end

            print_status "Listening on http#{'s' if ssl}://#{options[:bind]}:#{options[:port]}"

            begin
                server.run.join
            rescue Interrupt
                server.stop( true )
            end
        end
    end

end

end
end
