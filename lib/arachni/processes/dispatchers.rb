=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Processes

#
# Helper for managing {RPC::Server::Dispatcher} processes.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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

    # Connects to a Dispatcher by URL.
    #
    # @param    [String]    url URL of the Dispatcher.
    # @param    [Hash]    options Options for the RPC client.
    #
    # @return   [RPC::Client::Dispatcher]
    def connect( url, options = { } )
        Reactor.global.run_in_thread if !Reactor.global.running?

        options[:client_max_retries] = options.delete(:max_retries)

        fresh = options.delete( :fresh )

        opts     = OpenStruct.new
        opts.rpc = OpenStruct.new( options )

        if fresh
            @dispatcher_connections[url] = RPC::Client::Dispatcher.new( opts, url )
        else
            @dispatcher_connections[url] ||= RPC::Client::Dispatcher.new( opts, url )
        end
    end

    # @param    [Block] block   Block to pass an RPC client for each Dispatcher.
    def each( &block )
        @list.each do |url|
            block.call connect( url )
        end
    end

    # Spawns a {RPC::Server::Dispatcher} process.
    #
    # @param    [Hash]  options
    #   To be passed to {Arachni::Options#set}. Allows `address` instead of
    #   `rpc_server_address` and `port` instead of `rpc_port`.
    #
    # @return   [RPC::Client::Dispatcher]
    def spawn( options = {} )
        fork = options.delete(:fork)

        options = {
            dispatcher: {
                neighbour:        options[:neighbour],
                node_pipe_id:     options[:pipe_id],
                node_weight:      options[:weight],
                external_address: options[:external_address],
                pool_size:        options[:pool_size]
            },
            rpc:        {
                server_port:    options[:port]    || Utilities.available_port,
                server_address: options[:address] || '127.0.0.1'
            }
        }

        Manager.spawn( :dispatcher, options: options, fork: fork )

        url = "#{options[:rpc][:server_address]}:#{options[:rpc][:server_port]}"
        while sleep( 0.1 )
            begin
                connect( url, connection_pool_size: 1, max_retries: 1 ).alive?
                break
            rescue => e
                # ap e
            end
        end

        @list << url
        connect( url, fresh: true )
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
        Manager.kill_many dispatcher.statistics['consumed_pids']
        Manager.kill dispatcher.pid
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
