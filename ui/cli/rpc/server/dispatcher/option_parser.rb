=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative '../../../option_parser'

module Arachni
module UI::CLI
module RPC
module Server

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Dispatcher
class OptionParser < UI::CLI::OptionParser

    attr_reader :cli

    def initialize
        super

        separator 'Server'

        on( '--address ADDRESS', 'Hostname or IP address to bind to.',
               "(Default: #{options.rpc.server_address})"
        ) do |address|
            options.rpc.server_address = address
        end

        on( '--external-address ADDRESS', 'Hostname or IP address to advertise.',
               "(Default: #{options.rpc.server_address})"
        ) do |address|
            options.dispatcher.external_address = address
        end

        on( '--port NUMBER', 'Port to listen to.', Integer,
               "(Default: #{options.rpc.server_port})"
        ) do |port|
            options.rpc.server_port = port
        end

        on( '--port-range BEGINNING-END',
               'Specify port range for the spawned RPC instances.',
               "(Default: #{options.dispatcher.instance_port_range.join( '-' )})"
        ) do |range|
            options.dispatcher.instance_port_range = range.split( '-' ).map(&:to_i)
        end

        on( '--pool-size SIZE', Integer,
               'How many Instances to have available at any given time.',
               "(Default: #{options.dispatcher.pool_size})"
        ) do |pool_size|
            options.dispatcher.pool_size = pool_size
        end

        separator ''
        separator 'Output'

        on( '--reroute-to-logfile',
               "Reroute all output to log-files under: #{options.paths.logs}"
        ) do
            options.output.reroute_to_logfile = true
        end

        on( '-v', '--verbose', 'Show verbose output.',
               "(Only applicable when '--reroute-to-logfile' is enabled.)"
        ) do
            verbose
        end

        on( '-d', '--debug', 'Show debugging information.',
               "(Only applicable when '--reroute-to-logfile' is enabled.)"
        ) do
            debug
        end

        on( '--only-positives', 'Only output positive results.',
               "(Only applicable when '--reroute-to-logfile' is enabled.)"
        ) do
            only_positives
        end

        separator ''
        separator 'Grid'

        on( '--neighbour URL', 'URL of a neighbouring Dispatcher.' ) do |url|
            options.dispatcher.neighbour = url
        end

        on( '--weight FLOAT', Float, 'Weight of this node.' ) do |url|
            options.dispatcher.node_weight = url
        end

        on( '--pipe-id ID', 'Identifier for the attached bandwidth pipe.' ) do |id|
            options.dispatcher.node_pipe_id = id
        end

        on( '--nickname NAME', 'Nickname for this Dispatcher.' ) do |name|
            options.dispatcher.node_name = name
        end

        separator ''
        separator 'SSL'

        on( '--ssl-ca FILE',
               'Location of the CA certificate (.pem).'
        ) do |file|
            options.rpc.ssl_ca = file
        end

        on( '--server-ssl-private-key FILE',
               'Location of the server SSL private key (.pem).'
        ) do |file|
            options.rpc.server_ssl_private_key = file
        end

        on( '--server-ssl-certificate FILE',
               'Location of the server SSL certificate (.pem).'
        ) do |file|
            options.rpc.server_ssl_certificate = file
        end

        on( '--client-ssl-private-key FILE',
               'Location of the client SSL private key (.pem).'
        ) do |file|
            options.rpc.client_ssl_private_key = file
        end

        on( '--client-ssl-certificate FILE',
               'Location of the client SSL certificate (.pem).'
        ) do |file|
            options.rpc.client_ssl_certificate = file
        end
    end

end
end
end
end
end
end
