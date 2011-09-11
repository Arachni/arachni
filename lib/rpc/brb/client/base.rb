=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'brb'

module Arachni
module RPC
module BrB
module Client

#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Base

    #
    # Maps the methods of remote objects to local ones
    #
    class Mapper

        def initialize( server, remote )
            @server = server
            @remote = remote
        end

        private
        #
        # Used to provide the illusion of locality for remote methods
        #
        def method_missing( sym, *args, &block )
            call = "#{@remote}.#{sym.to_s}"
            @server.call( call, *args )
        end

    end


    def initialize( opts, url, token = nil )

        @@cache ||= {}

        @opts   = opts

        @url    = url.include?( 'brb://' ) ? url : 'brb://' + url
        @token  = token

        @@cache[@url] ||= ::BrB::Tunnel.create( nil, @url )
    end

    def close
        ::EM.stop
    end

    def call( expr, *args, &block )

        # ap expr
        # ap args

        if !block_given?
            @@cache[@url].call_block( expr, *args )
        else
            @@cache[@url].call( expr, *args, &block )
        end
    end


end

end
end
end
end