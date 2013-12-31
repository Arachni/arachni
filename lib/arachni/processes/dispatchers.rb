=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
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

    # Connects to a Dispatcher by URL.
    #
    # @param    [String]    url URL of the Dispatcher.
    # @param    [Hash]    options Options for the RPC client.
    #
    # @return   [RPC::Client::Dispatcher]
    def connect( url, options = { } )
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
    # @param    [Block] block
    #   Passed {Arachni::Options} to configure the Dispatcher options.
    #
    # @return   [RPC::Client::Dispatcher]
    def spawn( options = {}, &block )
        options = Options.to_h.merge(
            dispatcher: {
                neighbour:        options[:neighbour],
                node_pipe_id:     options[:pipe_id],
                node_weight:      options[:weight],
                external_address: options[:external_address],
                pool_size:        options[:pool_size]
            },
            rpc: {
                server_port:    options[:port] || available_port,
                server_address: options[:address] || 'localhost'
            }
        )
        url = "#{options[:rpc][:server_address]}:#{options[:rpc][:server_port]}"

        Manager.fork_em do
            Options.set( options )
            block.call( Options.instance ) if block_given?

            require "#{Arachni::Options.paths.lib}/rpc/server/dispatcher"

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
