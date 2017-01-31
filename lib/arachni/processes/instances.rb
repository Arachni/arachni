=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Processes

#
# Helper for managing {RPC::Server::Instance} processes.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
class Instances
    include Singleton
    include Utilities

    # @return   [Array<String>] URLs and tokens of all running Instances.
    attr_reader :list

    def initialize
        @list = {}
        @instance_connections = {}
    end

    #
    # Connects to a Instance by URL.
    #
    # @param    [String]    url URL of the Dispatcher.
    # @param    [String]    token
    #   Authentication token -- only need be provided once.
    #
    # @return   [RPC::Client::Instance]
    #
    def connect( url, token = nil )
        Reactor.global.run_in_thread if !Reactor.global.running?

        token ||= @list[url]
        @list[url] ||= token

        @instance_connections[url] ||=
            RPC::Client::Instance.new( Options, url, token )
    end

    # @param    [Block] block   Block to pass an RPC client for each Instance.
    def each( &block )
        @list.keys.each do |url|
            block.call connect( url )
        end
    end

    #
    # @param    [String, RPC::Client::Instance] client_or_url
    #
    # @return   [String]    Cached authentication token for the given Instance.
    #
    def token_for( client_or_url )
        @list[client_or_url.is_a?( String ) ? client_or_url : client_or_url.url ]
    end

    # Spawns an {RPC::Server::Instance} process.
    #
    # @param    [Hash]  options
    #   To be passed to {Arachni::Options#set}. Allows `address` instead of
    #   `rpc_server_address` and `port` instead of `rpc_port`.
    #
    # @return   [RPC::Client::Instance]
    def spawn( options = {}, &block )
        token = options.delete(:token) || Utilities.generate_token
        fork  = options.delete(:fork)

        options = {
            spawns: options[:spawns],
            rpc:    {
                server_socket:  options[:socket],
                server_port:    options[:port]    || Utilities.available_port,
                server_address: options[:address] || '127.0.0.1'
            }
        }

        url = nil
        if options[:rpc][:server_socket]
            url = options[:rpc][:server_socket]

            options[:rpc].delete :server_address
            options[:rpc].delete :server_port
        else
            url = "#{options[:rpc][:server_address]}:#{options[:rpc][:server_port]}"
        end

        Manager.spawn( :instance, options: options, token: token, fork: fork )

        client = connect( url, token )

        if block_given?
            client.when_ready do
                block.call client
            end
        else
            while sleep( 0.1 )
                begin
                    client.service.alive?
                    break
                rescue => e
                    # ap "#{e.class}: #{e}"
                    # ap e.backtrace
                end
            end
            client
        end
    end

    # Starts {RPC::Server::Dispatcher} grid and returns a high-performance Instance.
    #
    # @param    [Hash]  options
    # @option options [Integer] :grid_size (3)  Amount of Dispatchers to spawn.
    #
    # @return   [RPC::Client::Instance]
    def grid_spawn( options = {} )
        options[:grid_size] ||= 3

        last_member = nil
        options[:grid_size].times do |i|
            last_member = Dispatchers.spawn(
                neighbour: last_member ? last_member.url : last_member,
                pipe_id:   Utilities.available_port.to_s + Utilities.available_port.to_s
            )
        end

        info = last_member.dispatch

        instance = connect( info['url'], info['token'] )
        instance.framework.set_as_master
        instance.options.set( dispatcher: { grid_mode: :aggregate } )
        instance
    end

    # Starts {RPC::Server::Dispatcher} grid and returns a high-performance Instance.
    #
    # @param    [Hash]  options
    # @option options [Integer] :grid_size (3)  Amount of Dispatchers to spawn.
    #
    # @return   [RPC::Client::Instance]
    def light_grid_spawn( options = {} )
        options[:grid_size] ||= 3

        last_member = nil
        options[:grid_size].times do |i|
            last_member = Dispatchers.light_spawn(
                neighbour: last_member ? last_member.url : last_member,
                pipe_id:   Utilities.available_port.to_s + Utilities.available_port.to_s
            )
        end

        info = nil
        info = last_member.dispatch while !info && sleep( 0.1 )

        instance = connect( info['url'], info['token'] )
        instance.framework.set_as_master
        instance.options.set( dispatcher: { grid_mode: :aggregate } )
        instance
    end

    #
    # Starts {RPC::Server::Dispatcher} and returns an Instance.
    #
    # @return   [RPC::Client::Instance]
    #
    def dispatcher_spawn
        info = Dispatchers.light_spawn.dispatch
        connect( info['url'], info['token'] )
    end

    def kill( url )
        service = connect( url ).service
        service.consumed_pids do |pids|
            service.shutdown do
                # Make sure....
                Manager.kill_many pids
            end
        end

        @list.delete url
    end

    # Kills all {Instances #list}.
    def killall
        pids = []
        each do |instance|
            begin
                Timeout.timeout 5 do
                    pids |= instance.service.consumed_pids
                end
            rescue => e
                #ap e
                #ap e.backtrace
            end
        end

        each do |instance|
            begin
                Timeout.timeout 5 do
                    instance.service.shutdown
                end
            rescue => e
                #ap e
                #ap e.backtrace
            end
        end

        @list.clear
        @instance_connections.clear
        Manager.kill_many pids
    end

    def self.method_missing( sym, *args, &block )
        if instance.respond_to?( sym )
            instance.send( sym, *args, &block )
        else
            super( sym, *args, &block )
        end
    end

    def self.respond_to?( m )
        super( m ) || instance.respond_to?( m )
    end
end

end
end
