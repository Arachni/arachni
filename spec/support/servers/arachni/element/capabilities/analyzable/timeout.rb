require 'sinatra'

get '/' do
    'Stuff'
end

get '/true' do
    wait = params[:sleep].to_f
    wait /= 1000.0 if params[:mili] == 'true'

    sleep( wait )

<<-EOHTML
    <a href='?sleep=0&mili=#{params[:mili]}'>Inject here</a>
EOHTML
end

get '/add' do
    sleep_time = params[:sleep].to_f - 1

    if sleep_time > 0
        sleep( sleep_time ).to_s
    end
end

get '/sleep' do
    sleep 10
    'Stuff'
end

get '/verification_fail' do
    @@called ||= false

    if !@@called
        sleep params[:sleep].to_f
        @@called = true
    end

    'Stuff'
end

get '/waf' do
    next if !params[:sleep]

    sleep 10 if params[:sleep].include?( 'payload' )
end
