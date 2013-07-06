require 'sinatra'

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

get %r{^/(\d+)$} do |id|
    html = ''

    10.times do |i|
        html << <<-EOHTML
        <a href='/#{id}/#{i}'>Stuff</a>
        EOHTML
    end
    html
end

get %r{^/(\d+)/(\d+)$} do |id, id2|
    html = ''

    50.times do |i|
        html << <<-EOHTML
        <a href='/#{id}/#{id2}/#{id}'>Stuff</a>
        EOHTML
    end
    html
end

get %r{^/(\d+)/(\d+)/(\d+)$} do |id, id2, id3|
    "<a href='/vulnerable?#{id2}_vulnerable_#{id3}=stuff#{id}'>Vulnerable</a>"
end
