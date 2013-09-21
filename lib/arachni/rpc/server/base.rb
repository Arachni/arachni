=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
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
