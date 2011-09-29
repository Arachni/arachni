=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

require Arachni::Options.instance.dir['lib'] + 'rpc/client/base'

module RPC
class Client

#
# BrBRPC Dispatcher client
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.3
#
class Dispatcher

    attr_reader :node

    def initialize( opts, url )
        @client = Base.new( opts, url )

        @node = Mapper.new( @client, 'node' )
    end

    def close
        @client.close
    end

    private
    #
    # Used to provide the illusion of locality for remote methods
    #
    def method_missing( sym, *args, &block )
        @client.call( "dispatcher.#{sym.to_s}", *args, &block )
    end

end

end
end
end
