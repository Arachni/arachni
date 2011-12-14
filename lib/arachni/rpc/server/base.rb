=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'arachni/rpc/em'

module Arachni
module RPC
class Server

#
# RPC server class
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Base < ::Arachni::RPC::EM::Server

    def initialize( opts, token = nil )
        super(
            :host  => opts.rpc_address,
            :port  => opts.rpc_port,
            :token => token,
            :ssl_ca     => opts.ssl_ca,
            :ssl_pkey   => opts.ssl_pkey,
            :ssl_cert   => opts.ssl_cert
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
