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
module Processes

#
# Helper for managing {RPC::Server::Dispatcher} processes.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Dispatchers
    include Singleton
    include Utilities

    # @return   [Array<String>] URLs of all running Dispatchers.
    attr_reader :list

    def initialize
        @list = []
        @dispatcher_connections = {}
    end

    #
    # Connects to a Dispatcher by URL.
    #
    # @param    [String]    url URL of the Dispatcher.
    # @param    [Hash]    options Options for the RPC client.
    #
    # @return   [RPC::Client::Dispatcher]
    #
    def connect( url, options = { } )
        opts = OpenStruct.new( options )
        @dispatcher_connections[url] ||= RPC::Client::Dispatcher.new( opts, url )
    end

    # @param    [Block] block   Block to pass an RPC client for each Dispatcher.
    def each( &block )
        @list.each do |url|
            block.call connect( url )
        end
    end

    #
    # Spawns a {RPC::Server::Dispatcher} process.
    #
    # @param    [Hash]  options
    #   To be passed to {Arachni::Options#set}. Allows `address` instead of
    #   `rpc_address` and `port` instead of `rpc_port`.
    #
    # @param    [Block] block
    #   Passed {Arachni::Options} to configure the Dispatcher options.
    #
    # @return   [RPC::Client::Dispatcher]
    #
    def spawn( options = {}, &block )
        options = Options.to_hash.symbolize_keys( false ).merge( options )

        options[:rpc_port]    = options.delete( :port ) if options.include?( :port )
        options[:rpc_address] = options.delete( :address ) if options.include?( :address )

        options[:rpc_port]    ||= available_port

        url = "#{options[:rpc_address]}:#{options[:rpc_port]}"

        Manager.fork_em do
            Options.set( options )
            block.call( Options.instance ) if block_given?

            require "#{Arachni::Options.dir['lib']}/rpc/server/dispatcher"

            RPC::Server::Dispatcher.new
        end

        begin
            Timeout.timeout( 10 ) do
                while sleep( 0.1 )
                    begin
                        connect( url, max_retries: 1 ).alive?
                        break
                    rescue Exception
                    end
                end
            end
        rescue Timeout::Error
            abort "Dispatcher '#{url}' never started!"
        end

        @list << url
        connect( url )
    end

    # Same as {#spawn} but sets the pool size to `1`.
    def light_spawn( options = {}, &block )
        spawn( options.merge( pool_size: 1 ), &block )
    end

    # @note Will also kill all Instances started by the Dispatcher.
    #
    # @param    [String]    url URL of the Dispatcher to kill.
    def kill( url )
        dispatcher = connect( url )
        Manager.kill_many dispatcher.stats['consumed_pids']
        Manager.kill dispatcher.proc_info['pid'].to_i
    rescue => e
        #ap e
        #ap e.backtrace
        nil
    ensure
        @list.delete( url )
        @dispatcher_connections.delete( url )
    end

    # Kills all {Dispatchers #list}.
    def killall
        @list.dup.each do |url|
            kill url
        end
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
