=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

require Arachni::Options.instance.dir['lib'] + 'rpc/brb/client/base'

module RPC
module BrB
module Client

#
# BrBRPC Dispatcher client
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.3
#
class Dispatcher < Base

    attr_reader :node

    def initialize( opts, url )
        super( opts, url )

        @node = Mapper.new( self, 'node' )
    end

    private
    #
    # Used to provide the illusion of locality for remote methods
    #
    def method_missing( sym, *args, &block )
        call( "dispatcher.#{sym.to_s}", *args )
    end

end

end
end
end
end
