=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::OptionGroups

# Holds {Arachni::RPC::Client} and {Arachni::RPC::Server} options.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class RPC < Arachni::OptionGroup

    # @return   [String]
    #   Path to the UNIX socket to use for RPC communication.
    #
    # @see RPC::Server::Base
    attr_accessor :server_socket

    # @return   [String]
    #   Hostname or IP address for the RPC server.
    #
    # @see RPC::Server::Base
    attr_accessor :server_address

    # @return   [Integer]
    #   RPC server port.
    #
    # @see RPC::Server::Base
    attr_accessor :server_port

    # @return   [String]
    #   Path to an SSL certificate authority file in PEM format.
    #
    # @see RPC::Server::Base
    # @see RPC::Client::Base
    attr_accessor :ssl_ca

    # @return   [String]
    #   Path to a server SSL private key in PEM format.
    #
    # @see RPC::Server::Base
    attr_accessor :server_ssl_private_key

    # @return   [String]
    #   Path to server SSL certificate in PEM format.
    #
    # @see RPC::Server::Base
    attr_accessor :server_ssl_certificate

    # @return   [String]
    #   Path to a client SSL private key in PEM format.
    #
    # @see RPC::Client::Base
    attr_accessor :client_ssl_private_key

    # @return   [String]
    #   Path to client SSL certificate in PEM format.
    #
    # @see RPC::Client::Base
    attr_accessor :client_ssl_certificate

    # @return [Integer]
    #   Maximum retries for failed RPC calls.
    #
    # @see RPC::Client::Base
    attr_accessor :client_max_retries

    # @note This should be permanently set to `1`, otherwise it will cause issues
    #   with the scheduling of the workload distribution of multi-Instance scans.
    #
    # @return [Integer]
    #   Amount of concurrently open connections for each RPC client.
    #
    # @see RPC::Client::Base
    attr_accessor :connection_pool_size

    set_defaults(
        connection_pool_size: 1,
        server_address:       '127.0.0.1',
        server_port:          7331
    )

end
end
