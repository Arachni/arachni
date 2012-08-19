=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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
    # @param    [Arachni::Options]   opts   relevant options:
    #                                          * ssl_ca -- CA file (.pem)
    #                                          * node_ssl_pkey OR ssl_pkey -- private key file (.pem)
    #                                          * node_ssl_cert OR ssl_cert -- cert file file (.pem)
    # @param    [String]    url       server URL in <host>:<port> format
    # @param    [String]    token     optional authentication token
    #
    def initialize( opts, url, token = nil )
        @url = url
        host, port = url.split( ':' )
        super(
            host:        host,
            port:        port,
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
