=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'arachni/rpc'
require_relative '../serializer'

module Arachni
module RPC
class Client

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Base < Client
    attr_reader :url

    # @param    [Arachni::Options]   options
    #   Relevant options:
    #
    #     * {OptionGroups::RPC#ssl_ca}
    #     * {OptionGroups::RPC#client_ssl_private_key}
    #     * {OptionGroups::RPC#client_ssl_certificate}
    # @param    [String]    url
    #   Server URL in `address:port` format.
    # @param    [String]    token
    #   Optional authentication token.
    def initialize( options, url, token = nil )
        @url = url

        socket, host, port = nil
        if url.include? ':'
            host, port = url.split( ':' )
        else
            socket = url
        end

        super(
            serializer:           Serializer,
            host:                 host,
            port:                 port.to_i,
            socket:               socket,
            token:                token,
            connection_pool_size: options.rpc.connection_pool_size,
            max_retries:          options.rpc.client_max_retries,
            ssl_ca:               options.rpc.ssl_ca,
            ssl_pkey:             options.rpc.client_ssl_private_key,
            ssl_cert:             options.rpc.client_ssl_certificate
        )
    end

end
end
end
end
