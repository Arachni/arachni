# encoding: utf-8
require 'zlib'
require 'sinatra'
require 'sinatra/contrib'
set :logging, false

helpers do
    def simple_protected!
        return if simple_authorized?
        headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
        halt 401, "Not authorized\n"
    end

    def simple_authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials &&
            @auth.credentials == ['username', 'password']
    end

    def weird_protected!
        return if weird_authorized?
        headers['WWW-Authenticate'] = 'Basic realm="Restricted Area 2"'
        halt 401, "Not authorized\n"
    end

    def weird_authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? and @auth.basic? and @auth.credentials and
            @auth.credentials == ['u se rname$@#@#%$3#@%@#', 'p a  :wo\'rd$@#@#%$3#@%@#' ]
    end
end

get '/fingerprint.php' do
end

get '/http_response_max_size' do
    '1' * 1000000
end

get '/auth/simple-chars' do
    simple_protected!
    'authenticated!'
end

get '/auth/weird-chars' do
    weird_protected!
    'authenticated!'
end

post '/body' do
    request.body.read
end

post '/binary' do
    headers['Content-Type'] = 'application/binary'
    "\0"
end

get '/gzip' do
    headers['Content-Encoding'] = 'gzip'
    io = StringIO.new

    gz = Zlib::GzipWriter.new( io )
    begin
        gz.write( 'success' )
    ensure
        gz.close
    end
    io.string
end

get '/' do
    'GET'
end

post '/' do
    'POST'
end

delete '/' do
    'DELETE'
end

put '/' do
    'PUT'
end

options '/' do
    'OPTIONS'
end

get '/echo' do
    YAML.dump params
end

post '/echo' do
    YAML.dump env['rack.request.form_hash']
end

get '/redirect' do
    redirect '/redirect/1'
end

get '/redirect/1' do
    redirect '/redirect/2'
end

get '/redirect/2' do
    redirect '/redirect/3'
end

get '/redirect/3' do
    'This is the end.'
end

get '/sleep' do
    sleep 5
end

get '/set_and_preserve_cookies' do
    cookies['stuff'] = "=stuf \00 here=="
end

get '/cookies' do
    cookies.inject({}){ |h, (k, v)| h[k] = v; h}.to_yaml
end

get '/headers' do
    hash = env.reject{ |k, v| !k.to_s.downcase.include?( 'http' ) }.inject({}) do |h, (k, v)|
        k = k.split( '_' )[1..-1].map { |s| s.capitalize }.join( '-' )
        h[k] = v || ''; h
    end
    hash.to_yaml
end

get '/user-agent' do
    env['HTTP_USER_AGENT'].to_s
end

get '/update_cookies' do
    cookies[cookies.keys.first] = cookies.values.first + ' [UPDATED!]'
end

get '/follow_location' do
    redirect '/redir_1'
end

get '/redir_1' do
    redirect '/redir_2'
end

get '/redir_2' do
    'Welcome to redir_2!'
end

get '/custom_404/not' do
    'This is not a custom 404, watch out.'
end

get '/custom_404/static/*' do
    'This is a custom 404, try to catch it. ;)'
end

get '/custom_404/dynamic/*' do
    'This is a custom 404 which includes the requested resource, try to catch it. ;)' +
        '<br/>You asked for "' + params[:splat].first.to_s + '", which could not be found.'
end

get '/custom_404/random/*' do
    'This is a custom 404, try to catch it. ;)<br/> Random bit: ' + rand( 999 ).to_s
end

get '/custom_404/combo/*' do
    'This is a custom 404, try to catch it. ;)<br/> Random bit: ' + rand( 999 ).to_s +
        '<br/>You asked for "' + params[:splat].first.to_s + '", which could not be found.'
end
