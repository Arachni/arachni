=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

require Options.dir['lib'] + 'rpc/client/base'

module RPC
class Client

#
# RPC client for remote instances spawned by a remote dispatcher
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Instance

    attr_reader :opts
    attr_reader :spider
    attr_reader :framework
    attr_reader :modules
    attr_reader :plugins
    attr_reader :service

    #
    # Used to make remote option attributes look like setter methods
    #
    class OptsMapper < RemoteObjectMapper

        def method_missing( sym, *args, &block )
            return super( sym, *args, &block ) if sym == :set

            call  = "#{@remote}.#{sym.to_s}"

            if !args.empty? && !sym.to_s.end_with?( '=' ) &&
                Options.instance.methods.include?( "#{sym}=".to_sym  )
                call += '='
            end

            @server.call( call, *args, &block )
        end

    end

    def initialize( opts, url, token = nil )
        @client = Base.new( opts, url, token )

        @opts      = OptsMapper.new( @client, 'opts' )
        @framework = RemoteObjectMapper.new( @client, 'framework' )
        @spider    = RemoteObjectMapper.new( @client, 'spider' )
        @modules   = RemoteObjectMapper.new( @client, 'modules' )
        @plugins   = RemoteObjectMapper.new( @client, 'plugins' )
        @service   = RemoteObjectMapper.new( @client, 'service' )
    end

    def url
        @client.url
    end

end

end
end
end
