=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Processes

#
# Helper for managing {RPC::Server::Instance} processes.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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
        token ||= @list[url]
        @list[url] ||= token

        @instance_connections[url] ||= RPC::Client::Instance.new( Options.instance, url, token )
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

    #
    # Spawns an {RPC::Server::Instance} process.
    #
    # @param    [Hash]  options
    #   To be passed to {Arachni::Options#set}. Allows `address` instead of
    #   `rpc_address` and `port` instead of `rpc_port`.
    #
    # @param    [Block] block
    #   Passed {Arachni::Options} to configure the Dispatcher options.
    #
    # @return   [RPC::Client::Instance]
    #
    def spawn( options = {}, &block )
        options[:token] ||= generate_token

        options = Options.to_hash.symbolize_keys( false ).merge( options )

        options[:rpc_port]    = options.delete( :port ) if options.include?( :port )
        options[:rpc_address] = options.delete( :address ) if options.include?( :address )
        options[:rpc_socket]  = options.delete( :socket ) if options.include?( :socket )

        options[:rpc_port]    ||= available_port

        url = nil
        if options[:rpc_socket]
            url = options[:rpc_socket]
            options.delete :rpc_address
            options.delete :rpc_port
        else
            url = "#{options[:rpc_address]}:#{options[:rpc_port]}"
        end

        Manager.fork_em do
            Options.set( options )
            block.call( Options.instance ) if block_given?

            require "#{Arachni::Options.dir['lib']}/rpc/server/instance"

            RPC::Server::Instance.new( Options.instance, options[:token] )
        end

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

        @list[url] = options[:token]
        connect( url )
    end

    #
    # Starts {RPC::Server::Dispatcher} grid and returns a high-performance Instance.
    #
    # @param    [Hash]  options
    # @option options [Integer] :grid_size (2)  Amount of Dispatchers to spawn.
    #
    # @return   [RPC::Client::Instance]
    #
    def grid_spawn( options = {} )
        options[:grid_size] ||= 3

        last_member = nil
        options[:grid_size].times do |i|
            last_member = Dispatchers.spawn(
                neighbour: last_member ? last_member.url : last_member,
                pipe_id:   available_port.to_s + available_port.to_s
            )
        end

        info = last_member.dispatch

        instance = connect( info['url'], info['token'] )
        instance.framework.set_as_master
        instance.opts.grid_mode = :aggregate
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

    # Kills all {Instances #list}.
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

        @list.clear
        @instance_connections.clear
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
