=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative '../../output'
require_relative '../../option_parser'

module Arachni
module UI::CLI
module Rest
class Server

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class OptionParser < UI::CLI::OptionParser

    attr_reader :cli
    attr_reader :username
    attr_reader :password

    def initialize
        super

        separator 'Server'

        on( '--address ADDRESS', 'Hostname or IP address to bind to.',
            "(Default: #{options.rpc.server_address})"
        ) do |address|
            options.rpc.server_address = address
        end

        on( '--port NUMBER', 'Port to listen to.', Integer,
            "(Default: #{options.rpc.server_port})"
        ) do |port|
            options.rpc.server_port = port
        end

        separator ''
        separator 'Output'

        on( '--reroute-to-logfile',
            "Reroute scan output to log-files under: #{options.paths.logs}"
        ) do
            options.output.reroute_to_logfile = true
        end

        on( '--verbose', 'Show verbose output.',
            "(Only applicable when '--reroute-to-logfile' is enabled.)"
        ) do
            verbose_on
        end

        on( '--debug [LEVEL 1-3]', Integer, 'Show debugging information.',
            "(Only applicable when '--reroute-to-logfile' is enabled.)"
        ) do |level|
            debug_on( level || 1 )
        end

        on( '--only-positives', 'Only output positive results.',
            "(Only applicable when '--reroute-to-logfile' is enabled.)"
        ) do
            only_positives
        end

        separator ''
        separator 'Authentication'

        on( '--authentication-username USERNAME',
            'Username to use for HTTP authentication.'
        ) do |username|
            @username = username
        end

        on( '--authentication-password PASSWORD',
            'Password to use for HTTP authentication.'
        ) do |password|
            @password = password
        end

        # Puma SSL doesn't seem to be working on MS Windows.
        if !Arachni.windows?
            separator ''
            separator 'SSL'

            on( '--ssl-ca FILE',
                'Location of the CA certificate (.pem).',
                'If provided, peer verification will be enabled, otherwise no' +
                    ' verification will take place.'
            ) do |file|
                options.rpc.ssl_ca = file
            end

            on( '--ssl-private-key FILE',
                'Location of the SSL private key (.pem).'
            ) do |file|
                options.rpc.server_ssl_private_key = file
            end

            on( '--ssl-certificate FILE',
                'Location of the SSL certificate (.pem).'
            ) do |file|
                options.rpc.server_ssl_certificate = file
            end
        end
    end

end

end
end
end
end
