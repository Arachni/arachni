=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

require Options.paths.lib + 'rpc/client/base'

module RPC
class Client

# RPC client for remote instances spawned by a remote dispatcher
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Instance
    attr_reader :options
    attr_reader :framework
    attr_reader :checks
    attr_reader :plugins
    attr_reader :service

    require_relative 'instance/framework'
    require_relative 'instance/service'

    class <<self

        def when_ready( url, token, &block )
            options     = OpenStruct.new
            options.rpc = OpenStruct.new( Arachni::Options.to_h[:rpc] )
            options.rpc.client_max_retries   = 0
            options.rpc.connection_pool_size = 1

            client = new( options, url, token )
            Reactor.global.delay( 0.1 ) do |task|
                client.service.alive? do |r|
                    if r.rpc_exception?
                        Reactor.global.delay( 0.1, &task )
                        next
                    end

                    client.close

                    block.call
                end
            end
        end

    end

    def initialize( options, url, token = nil )
        @token  = token
        @client = Base.new( options, url, token )

        @framework = Framework.new( @client )
        @service   = Service.new( @client )

        @options   = Proxy.new( @client, 'options' )
        @checks    = Proxy.new( @client, 'checks' )
        @plugins   = Proxy.new( @client, 'plugins' )
    end

    def when_ready( &block )
        self.class.when_ready( url, token, &block )
    end

    def token
        @token
    end

    def close
        @client.close
    end

    def url
        @client.url
    end

end

end
end
end
