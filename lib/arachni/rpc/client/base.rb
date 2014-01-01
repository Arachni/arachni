=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

require 'arachni/rpc/em'

module Arachni
module RPC
class Client

#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Base < ::Arachni::RPC::EM::Client
    attr_reader :url

    #
    # @param    [Arachni::Options]   opts
    #   Relevant options:
    #
    #     * `ssl_ca` -- CA file (.pem).
    #     * `node_ssl_pkey` OR `ssl_pkey` -- Private key file (.pem).
    #     * `node_ssl_cert` OR `ssl_cert` -- Cert file file (.pem).
    # @param    [String]    url       Server URL in `address:port` format.
    # @param    [String]    token     Optional authentication token.
    #
    def initialize( opts, url, token = nil )
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
            max_retries: opts.max_retries,
            ssl_ca:      opts.ssl_ca,
            ssl_pkey:    opts.node_ssl_pkey || opts.ssl_pkey,
            ssl_cert:    opts.node_ssl_cert || opts.ssl_cert
        )
    end

end
end
end
end
