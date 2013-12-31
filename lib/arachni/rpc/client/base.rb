=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'arachni/rpc/em'

module Arachni
module RPC
class Client

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Base < ::Arachni::RPC::EM::Client
    attr_reader :url

    # @param    [Arachni::Options]   options
    #   Relevant options:
    #
    #     * {OptionGroups::RPC#ssl_ca}
    #     * {OptionGroups::RPC#client_ssl_private_key}
    #     * {OptionGroups::RPC#client_ssl_certificate}
    # @param    [String]    url       Server URL in `address:port` format.
    # @param    [String]    token     Optional authentication token.
    def initialize( options, url, token = nil )
        @url = url

        socket, host, port = nil
        if url.include? ':'
            host, port = url.split( ':' )
        else
            socket = url
        end

        super(
            serializer:  Marshal,
            host:        host,
            port:        port,
            socket:      socket,
            token:       token,
            max_retries: options.rpc.client_max_retries,
            ssl_ca:      options.rpc.ssl_ca,
            ssl_pkey:    options.rpc.client_ssl_private_key,
            ssl_cert:    options.rpc.client_ssl_certificate
        )
    end

end
end
end
end
