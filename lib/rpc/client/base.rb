=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'arachni/rpc'
require 'yaml'

module Arachni
module RPC

class Client

#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Base < ::Arachni::RPC::Client

    def initialize( opts, url, token = nil )
        host, port = url.split( ':' )
        super(
            :host  => host,
            :port  => port,
            :token => token,
            :keep_alive => false,
            :ssl_ca     => opts.ssl_ca,
            :ssl_pkey   => opts.ssl_pkey,
            :ssl_cert   => opts.ssl_cert
        )
    end

end
end
end
end