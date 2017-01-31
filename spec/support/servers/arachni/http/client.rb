# encoding: utf-8
require 'zlib'
require 'json'
require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/streaming'

helpers Sinatra::Streaming

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


get '/raw' do
    {
        'query' => env['QUERY_STRING'],
        'body'  => request.body.read
    }.to_json
end

post '/raw' do
    {
        'query' => env['QUERY_STRING'],
        'body'  => request.body.read
    }.to_json
end

get '/partial' do
    [ 200, { 'Content-Length' => '1000' }, 'Hello!' ]
end

get '/partial_stream' do
    stream do |out|
        5.times do |i|
            out.puts "#{i}: Hello!"
            out.close
        end

        out.flush
    end
end

get '/stream' do
    stream do |out|
        5.times do |i|
            out.puts "#{i}: Hello!"
            sleep 1
        end

        out.flush
    end
end

get '/fail_stream' do
    stream do |out|
        fail

        out.flush
    end
end

get '/fast_stream' do
    stream do |out|
        5.times do |i|
            out.puts "#{i}: Hello!"
        end

        out.flush
    end
end

get '/lines' do
    stream do |out|
        500.times do |i|
            out.puts "#{i}: test"
        end
        out.flush
    end
end

get '/lines/non-stream' do
    s = ''
    2_000.times do |i|
        s << "#{i}: test\n"
    end
    s
end

get '/lines/incomplete' do
    [ 200, { 'Content-Length' => '1000' }, "Blah\nHello!" ]
end

get '/fingerprint.php' do
end

get '/http_response_max_size' do
    '1' * 1000000
end

get '/http_response_max_size/without_content_length' do
    headers 'Content-Type' => ''
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
