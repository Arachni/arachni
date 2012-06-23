require 'sinatra'

get '/' do
    <<-EOHTML
        <object width="400" height="400" data="helloworld.swf"></object>
    EOHTML
end
