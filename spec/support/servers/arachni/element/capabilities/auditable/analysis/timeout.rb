require 'sinatra'
set :logging, false

get '/false' do
    sleep 2
<<-EOHTML
    <a href='?sleep=0'>Inject here</a>
    #{params[:input]}
EOHTML
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
    sleep( params[:sleep].to_f - 1 ).to_s
end

get '/high_response_time' do
    sleep( params[:sleep].to_i + 2 )
    <<-EOHTML
        <a href='?sleep=0'>Inject here</a>
EOHTML
end

get( '/sleep' ) { sleep 10 }
