=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'server/option_parser'

module Arachni

require Options.paths.lib + 'rest/server'
require_relative '../utilities'

module UI::CLI
module Rest

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Server

    def initialize
        parser = OptionParser.new
        parser.parse

        Arachni::Rest::Server.run!(
            port:            Arachni::Options.rpc.server_port,
            bind:            Arachni::Options.rpc.server_address,

            username:        parser.username,
            password:        parser.password,

            ssl_ca:          Arachni::Options.rpc.ssl_ca,
            ssl_key:         Arachni::Options.rpc.server_ssl_private_key,
            ssl_certificate: Arachni::Options.rpc.server_ssl_certificate
        )
    end

end

end
end
end
