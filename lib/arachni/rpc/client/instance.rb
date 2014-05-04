=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

require Options.paths.lib + 'rpc/client/base'

module RPC
class Client

# RPC client for remote instances spawned by a remote dispatcher
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Instance
    attr_reader :options
    attr_reader :framework
    attr_reader :checks
    attr_reader :plugins
    attr_reader :service

    require_relative 'instance/framework'
    require_relative 'instance/service'

    def initialize( options, url, token = nil )
        @token  = token
        @client = Base.new( options, url, token )

        @framework = Framework.new( @client )
        @service   = Service.new( @client )

        @options   = Proxy.new( @client, 'options' )
        @checks    = Proxy.new( @client, 'checks' )
        @plugins   = Proxy.new( @client, 'plugins' )
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
