=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative '../../../output'
require_relative '../../../option_parser'

module Arachni
module UI::CLI
module RPC
module Server
class Dispatcher

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
            options.dispatcher.node_nickname = name
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

        separator ''
        separator 'Snapshot'

        on( '--snapshot-save-path DIRECTORY', String,
            'Directory under which to store snapshots of suspended scans.' ) do |path|
            options.snapshot.save_path = path
        end
    end

    def validate
        validate_snapshot_save_path
    end

    def validate_snapshot_save_path
        snapshot_path = options.snapshot.save_path
        return if !snapshot_path || File.directory?( snapshot_path )

        $stderr.puts "Snapshot directory does not exist: #{snapshot_path}"
        exit 1
    end

end
end
end
end
end
end
