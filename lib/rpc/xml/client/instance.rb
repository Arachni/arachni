=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'xmlrpc/client'
require 'openssl'

module Arachni

require Arachni::Options.instance.dir['lib'] + 'rpc/xml/client/base'

module RPC
module XML
module Client

#
# XMLRPC client for remote instances spawned by a remote dispatcher
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.3
#
class Instance < Base

    attr_reader :opts
    attr_reader :framework
    attr_reader :modules
    attr_reader :plugins
    attr_reader :service

    #
    # Used to make remote option attributes look like setter methods
    #
    class OptsMapper < Mapper

        def method_missing( sym, *args, &block )
            return super( sym, *args, &block ) if sym == :set

            call = "#{@remote}.#{sym.to_s}="
            @server.call( call, *args )
        end

    end

    class Framework < Mapper

        def method_missing( sym, *args, &block )

            if sym == :clean_up!
                timeout = @server.timeout
                @server.timeout = 15
            end

            res = super( sym, *args, &block )

            if sym == :clean_up!
                @server.timeout = timeout
            end

            return res
        end

    end

    def initialize( opts, url, token = nil )
        super( opts, url, token )

        @opts      = OptsMapper.new( self, 'opts' )
        @framework = Framework.new( self, 'framework' )
        @modules   = Mapper.new( self, 'modules' )
        @plugins   = Mapper.new( self, 'plugins' )
        @service   = Mapper.new( self, 'service' )
    end

end

end
end
end
end
