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
class Server

#
# RPC server class
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Base < ::Arachni::RPC::EM::Server

    def initialize( opts, token = nil )
        super(
            serializer: Marshal,
            fallback_serializer:  YAML,
            host:       opts.rpc_address,
            port:       opts.rpc_port,
            socket:     opts.rpc_socket,
            token:      token,
            ssl_ca:     opts.ssl_ca,
            ssl_pkey:   opts.ssl_pkey,
            ssl_cert:   opts.ssl_cert
        )
    end

    def start
        super
        @ready = true
    end

    def ready?
        @ready ||= false
    end

end

end
end
end
