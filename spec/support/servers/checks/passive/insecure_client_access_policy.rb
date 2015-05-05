require 'sinatra'

get '/clientaccesspolicy.xml' do
    <<EOHTML
<allow-from http-request-headers="*">
    <domain uri="*"/>
</allow-from>
EOHTML
end
