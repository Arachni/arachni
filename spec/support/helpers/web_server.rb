=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

def web_server_url_for( *args )
    WebServerManager.url_for( *args )
end

def web_server_spawn( *args )
    WebServerManager.spawn( *args )
end

def web_server_killall
    WebServerManager.killall
end
