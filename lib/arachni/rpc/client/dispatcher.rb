=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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
# RPC Dispatcher client
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Dispatcher

    attr_reader :node

    def initialize( opts, url )
        @client = Base.new( opts, url )
        @node = RemoteObjectMapper.new( @client, 'node' )

        # map Dispatcher handlers
        Dir.glob( "#{Options.dir['rpcd_handlers']}*.rb" ).each do |handler|
            name = File.basename( handler, '.rb' )

            self.class.send( :attr_reader, name.to_sym )
            instance_variable_set( "@#{name}".to_sym, RemoteObjectMapper.new( @client, name ) )
        end
    end

    def url
        @client.url
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
