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
# BrBRPC client for remote instances spawned by a remote dispatcher
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.3
#
class Instance

    attr_accessor :timeout

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
            @server.call( call, *args, &block )
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
        @client = Base.new( opts, url, token )

        @opts      = OptsMapper.new( @client, 'opts' )
        @framework = Framework.new( @client, 'framework' )
        @modules   = Mapper.new( @client, 'modules' )
        @plugins   = Mapper.new( @client, 'plugins' )
        @service   = Mapper.new( @client, 'service' )
    end

end

end
end
end
