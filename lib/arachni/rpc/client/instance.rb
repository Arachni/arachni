=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
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
