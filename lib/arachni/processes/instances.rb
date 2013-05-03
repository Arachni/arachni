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
module Processes

class Instances
    include Singleton
    include Utilities

    attr_reader :instances

    def initialize
        @instances = {}
    end

    def connect( url, token = nil )
        token ||= @instances[url]
        @instances[url] ||= token

        RPC::Client::Instance.new( Options.instance, url, token )
    end

    def each( &block )
        @instances.keys.each do |url|
            block.call connect( url )
        end
    end

    def token_for( client_or_url )
        @instances[client_or_url.is_a?( String ) ? client_or_url : client_or_url.url ]
    end

    def spawn( options = {} )
        options[:token] ||= generate_token

        options = Options.to_hash.symbolize_keys( false ).merge( options )

        options[:rpc_port]    = options.delete( :port ) if options.include?( :port )
        options[:rpc_address] = options.delete( :address ) if options.include?( :address )

        options[:rpc_port]    ||= available_port

        url = "#{options[:rpc_address]}:#{options[:rpc_port]}"

        Manager.fork_em {
            Options.set( options )
            opts = Options.instance

            RPC::Server::Instance.new( opts, options[:token] )
        }

        begin
            Timeout.timeout( 10 ) do
                while sleep( 0.1 )
                    begin
                        connect( url, options[:token] ).service.alive?
                        break
                    rescue Exception
                    end
                end
            end
        rescue Timeout::Error
            abort "Instance '#{url}' never started!"
        end

        @instances[url] = options[:token]
        connect( url )
    end

    def grid_spawn( options = {} )
        options[:grid_size] ||= 2

        last_member = nil
        options[:grid_size].times do |i|
            last_member = Dispatchers.light_spawn(
                neighbour: last_member ? last_member.url : last_member,
                pipe_id:   available_port.to_s + available_port.to_s
            )
        end

        info = last_member.dispatch

        instance = connect( info['url'], info['token'] )
        instance.opts.grid_mode = 'high_performance'
        instance
    end

    def dispatcher_spawn
        info = Dispatchers.light_spawn.dispatch
        connect( info['url'], info['token'] )
    end

    def killall
        pids = []
        each do |instance|
            begin
                pids |= instance.service.consumed_pids
            rescue => e
                #ap e
                #ap e.backtrace
            end
        end

        @instances.clear
        Manager.kill_many pids
    end

    def self.method_missing( sym, *args, &block )
        if instance.respond_to?( sym )
            instance.send( sym, *args, &block )
        elsif
        super( sym, *args, &block )
        end
    end

    def self.respond_to?( m )
        super( m ) || instance.respond_to?( m )
    end
end

end
end
