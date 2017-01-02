=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative '../../../lib/arachni/processes/manager'
require_relative '../../../lib/arachni/processes/helpers'
require_relative '../../support/helpers/paths'
require_relative 'web_server_manager'
require 'arachni/rpc'

# @note Needs `ENV['WEB_SERVER_DISPATCHER']` in the format of `host:port`.
#
# Exposes the {WebServerManager} over RPC.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class WebServerDispatcher

    def initialize( options = {} )
        host, port = ENV['WEB_SERVER_DISPATCHER'].split( ':' )

        manager = WebServerManager.instance
        manager.address = host

        rpc = Arachni::RPC::Server.new( host: host, port: port.to_i )
        rpc.add_handler( 'server', manager )
        rpc.run
    end

end
