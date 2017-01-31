=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

def web_server_manager
    ENV['WEB_SERVER_DISPATCHER'] ? WebServerClient.instance : WebServerManager
end

def web_server_url_for( *args )
    web_server_manager.url_for( *args )
end

def web_server_spawn( *args )
    web_server_manager.spawn( *args )
end

def web_server_killall
    web_server_manager.killall
end
