=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

require Options.paths.lib + 'rpc/client/base'
require Options.paths.lib + 'rpc/client/proxy'

module RPC
class Client

# RPC client for remote instances spawned by a remote dispatcher
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Instance
    attr_reader :opts
    attr_reader :framework
    attr_reader :checks
    attr_reader :plugins
    attr_reader :service

    require_relative 'instance/framework'
    require_relative 'instance/options'
    require_relative 'instance/service'

    def initialize( opts, url, token = nil )
        @client = Base.new( opts, url, token )

        @opts      = Options.new( @client )
        @framework = Framework.new( @client )
        @checks    = RemoteObjectMapper.new( @client, 'checks' )
        @plugins   = RemoteObjectMapper.new( @client, 'plugins' )
        @service   = Service.new( @client )
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
