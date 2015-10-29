=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'sinatra'
require 'sinatra/contrib'

module Arachni
module Rest

class Server < Sinatra::Base
    lib = Options.paths.lib
    require lib + 'processes'
    require lib + 'rest/server/instance_helpers'

    helpers InstanceHelpers

    use Rack::Session::Pool

    enable :logging

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

    # List tokens.
    get '/scans' do
        json ids: instances.keys
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

        session[:seen_issues]  ||= []
        session[:seen_errors]  ||= 0
        session[:seen_sitemap] ||= 0

        data = scan_for( params[:id] ).progress(
            with:    [
                :issues,
                errors:  session[:seen_errors],
                sitemap: session[:seen_sitemap]
            ],
            without: [
                issues: session[:seen_issues]
            ]
        )

        data[:issues].each do |issue|
            session[:seen_issues] << issue['digest']
        end

        session[:seen_errors]  += data[:errors].size
        session[:seen_sitemap] += data[:sitemap].size

        json data
    end

    get '/scans/:id/report.:format' do
        fail_if_not_exists

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

        json nil
    end

end

end
end
