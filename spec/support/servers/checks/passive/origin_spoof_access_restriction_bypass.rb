require 'sinatra'

HEADERS = [
    'X-Forwarded-For',
    'X-Originating-IP',
    'X-Remote-IP',
    'X-Remote-Addr'
].map { |h| "HTTP_#{h.gsub( '-', '_' ).upcase}" }

ADDRESS = '127.0.0.1'

get '/' do
    HEADERS.map do |header|
        <<-EOHTML
            <a href="#{header}/401">401</a>
            <a href="#{header}/403">403</a>
        EOHTML
    end.join
end

HEADERS.each do |header|
    get "/#{header}/401" do
        env[header] == '127.0.0.1' ? 200 : 401
    end

    get "/#{header}/403" do
        env[header] == '127.0.0.1' ? 200 : 403
    end

end
