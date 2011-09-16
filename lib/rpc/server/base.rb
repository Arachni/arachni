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
class Server

#
# RPC server class
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Base < ::Arachni::RPC::Server

    def initialize( opts, token = nil )
        super(
            :host  => opts.rpc_address,
            :port  => opts.rpc_port,
            :token => token
        )
    end

end

end
end
end
