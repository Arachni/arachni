require 'sinatra'

def normal_response
    'Usual response...normal stuff'
end

def rejected
    'Piss off!'
end

def random
    (0..100).map{ rand( 9999 ).to_s }.join
end

@@request_cnt ||= 0

get '/positive' do
    params.to_s.include?( 'script' ) ? rejected : normal_response
end

get '/negative' do
    normal_response
end

get '/inconclusive' do
    @@request_cnt += 1

    if params.empty?
        normal_response
    else
        @@request_cnt % 2 == 0 ? rejected : normal_response
    end
end
