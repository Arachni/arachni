=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

require Options.dir['lib'] + 'rpc/server/output'

module RPC

#
# Dispatcher node class, helps maintain a list of all available Dispatchers in
# the grid and announce itself to neighbouring Dispatchers.
#
# As soon as a new Node is fired up it checks-in with its neighbour and grabs
# a list of all available peers.
#
# As soon as it receives the peer list it then announces itself to them.
#
# Upon convergence there will be a grid of Dispatchers each one with its own
# copy of all available Dispatcher URLs.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Server::Dispatcher::Node
    include UI::Output

    DEFAULT_PING_INTERVAL = 60

    #
    # Initializes the node by:
    #
    #   * Adding the neighbour (if the user has supplied one) to the peer list.
    #   * Getting the neighbour's peer list and appending them to its own.
    #   * Announces itself to the neighbour and instructs it to propagate our URL
    #     to the others.
    #
    # @param    [Arachni::Options]    opts
    # @param    [String]              logfile   Where to send the output.
    #
    def initialize( opts, logfile = nil )
        @opts = opts
        @opts.rpc_external_address ||= @opts.rpc_address

        @url = "#{@opts.rpc_external_address}:#{@opts.rpc_port}"

        reroute_to_file( logfile ) if logfile

        print_status 'Initializing grid node...'

        @dead_nodes = []
        @neighbours = Set.new
        @nodes_info_cache = []

        if (neighbour = @opts.neighbour)
            # add neighbour and announce him to everyone
            add_neighbour( neighbour, true )

            # grab the neighbour's neighbours
            peer = connect_to_peer( neighbour )
            peer.neighbours do |urls|
                fail "Neighbour '#{neighbour}' is unreachable." if urls.rpc_exception?
                urls.each { |url| @neighbours << url if url != @url }
            end
        end

        print_status( 'Node ready.' )

        log_updated_neighbours

        interval = @opts.node_ping_interval || DEFAULT_PING_INTERVAL
        ::EM.add_periodic_timer( interval ) do
            ping
            check_for_comebacks
        end
    end

    # @return   [Boolean]   `true` if grid member, `false` otherwise.
    def grid_member?
        @neighbours.any?
    end

    #
    # Adds a neighbour to the peer list.
    #
    # @param    [String]    node_url    URL of a neighbouring node.
    # @param    [Boolean]   propagate
    #   Whether or not to announce the new node to the peers.
    #
    def add_neighbour( node_url, propagate = false )
        # we don't want ourselves in the Set
        return false if node_url == @url
        return false if @neighbours.include?( node_url )

        print_status "Adding neighbour: #{node_url}"

        @neighbours << node_url
        log_updated_neighbours
        announce( node_url ) if propagate

        connect_to_peer( node_url ).add_neighbour( @url, propagate ) do |res|
            next if !res.rpc_exception?
            add_dead_neighbour( node_url )
            print_status "Neighbour seems dead: #{node_url}"
        end
        true
    end

    # @return   [Array] Neighbour/node/peer URLs.
    def neighbours
        @neighbours.to_a
    end

    def neighbours_with_info( &block )
        fail 'This method requires a block!' if !block_given?

        @neighbours_cmp = ''

        if @nodes_info_cache.empty? || @neighbours_cmp != neighbours.to_s
            @neighbours_cmp = neighbours.to_s

            each = proc do |neighbour, iter|
                connect_to_peer( neighbour ).info do |info|
                    if info.rpc_exception?
                        print_info "Neighbour seems dead: #{neighbour}"
                        add_dead_neighbour( neighbour )
                        log_updated_neighbours

                        iter.return( nil )
                    else
                        iter.return( info )
                    end
                end
            end

            after = proc do |nodes|
                @nodes_info_cache = nodes.compact
                block.call( @nodes_info_cache )
            end

            ::EM::Iterator.new( neighbours ).map( each, after )
        else
            block.call( @nodes_info_cache )
        end
    end

    # @return    [Hash]
    #   * `:url` -- This node's URL.
    #   * `:pipe_id` -- Bandwidth Pipe ID
    #   * `:weight` -- Weight
    #   * `:nickname` -- Nickname
    #   * `:cost` -- Cost
    def info
        {
            'url'      => @url,
            'pipe_id'  => @opts.pipe_id,
            'weight'   => @opts.weight,
            'nickname' => @opts.nickname,
            'cost'     => @opts.cost
        }
    end

    def alive?
        true
    end

    private

    def remove_neighbour( node_url )
        @neighbours -= [node_url]
    end

    def add_dead_neighbour( url )
        remove_neighbour( url )
        @dead_nodes << url
    end

    def log_updated_neighbours
        print_info 'Updated neighbours:'

        if !neighbours.empty?
            neighbours.each { |node| print_info( '---- ' + node ) }
        else
            print_info '<empty>'
        end
    end

    def ping
        neighbours.each do |neighbour|
            connect_to_peer( neighbour ).alive? do |res|
                next if !res.rpc_exception?
                add_dead_neighbour( neighbour )
                print_status "Found dead neighbour: #{neighbour} "
            end
        end
    end

    def check_for_comebacks
        @dead_nodes.dup.each do |url|
            neighbour = connect_to_peer( url )
            neighbour.alive? do |res|
                next if res.rpc_exception?

                print_status "Dispatcher came back to life: #{url}"
                ([@url] | neighbours).each do |node|
                    neighbour.add_neighbour( node ){}
                end

                add_neighbour( url )
                @dead_nodes -= [url]
            end
        end
    end

    #
    # Announces the node to the ones in the peer list
    #
    # @param    [String]    node    URL
    #
    def announce( node )
        print_status "Advertising: #{node}"

        neighbours.each do |peer|
            next if peer == node

            print_info '---- to: ' + peer
            connect_to_peer( peer ).add_neighbour( node ) do |res|
                add_dead_neighbour( peer ) if res.rpc_exception?
            end
        end
    end

    def connect_to_peer( url )
        Client::Dispatcher.new( @opts, url ).node
    end

end
end
end
