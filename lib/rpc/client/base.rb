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
            :token => token
        )
    end

    def call( msg, *args, &block )
        super( msg, *args, &block )
    end

end
end
end
end