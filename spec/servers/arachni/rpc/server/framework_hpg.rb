require 'sinatra'
set :logging, false

get '/vulnerable' do
    params.values.to_s
end

get '/' do
    html = ''

    50.times do |i|
        html << <<-EOHTML
        <a href='/#{i}'>Stuff</a>
        EOHTML
    end
    html
end

get '/:id' do |id|
    html = ''

    10.times do |i|
        html << <<-EOHTML
        <a href='/#{id}/#{i}'>Stuff</a>
        EOHTML
    end
    html
end

get '/:id/:id2' do |id, id2|
    html = ''

    50.times do |i|
        html << <<-EOHTML
        <a href='/#{id}/#{id2}/#{id}'>Stuff</a>
        EOHTML
    end
    html
end

get '/:id/:id2/:id3' do |id, id2, id3|
    "<a href='/vulnerable?#{id2}vuln#{id3}=stuff'>Vulnerable</a>"
end
