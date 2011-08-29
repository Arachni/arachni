=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end


module Arachni

require Options.instance.dir['lib'] + 'rpc/xml/server/output'

module RPC
module XML
module Server

class Dispatcher

#
# Dispatcher node class, helps maintain a list of all available Dispatchers in the grid
# and announce itself to neighbouring Dispatchers.
#
# As soon as a new Node is fired up it checks-in with its neighbour and grabs
# a list of all available peers.
#
# As soon as it receives the peer list it then announces itself to them.
#
# Upon convergence there will be a grid of Dispatchers each one with its own copy
# of all available Dispatcher URLs.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Node

    include Arachni::UI::Output

    #
    # Initializes the node by:
    # * Adding the neighbour (if the user has supplied one) to the peer list
    # * Getting the neighbour's peer list and appending them to its own
    # * Announces itself to the neighbour and instructs it to propagate our URL to the others
    #
    # @param    [Arachni::Options]    opts
    # @param    [String]              logfile   were to send the output
    #
    def initialize( opts, logfile )
        @opts = opts

        reroute_to_file( logfile )

        print_status( 'Initing grid node...' )

        @neighbours = Set.new
        @peer_conn_cache = {}

        if neighbour = @opts.neighbour
            add_neighbour( neighbour )

            get_peers( neighbour ).each {
                |url|
                @neighbours << url if url != @opts.datastore[:dispatcher_url]
            }

            peer = connect_to_peer( neighbour )
            peer.node.add_neighbour( opts.datastore[:dispatcher_url], true )

        end

        print_status( 'Node ready.' )

        print_info 'Initial neighbours:'
        neighbours.each {
            |node|
            print_info( '---- ' + node )
        }

    end

    #
    # Adds a neighbour to the peer list
    #
    # @param    [String]    node_url    URL of a neighbouring node
    # @param    [Boolean]   propagate   wether or not to announce the new node
    #                                    to the ones in the peer list
    #
    def add_neighbour( node_url, propagate = false )
        # we don't want ourselves in the Set
        return false if node_url == @opts.datastore[:dispatcher_url]

        print_status 'Adding neighbour: ' + node_url

        @neighbours << node_url

        print_info 'Updated neighbours:'
        neighbours.each {
            |node|
            print_info( '---- ' + node )
        }

        announce( node_url ) if propagate

        return true
    end

    #
    # Returns all neighbour/node/peer URLs
    #
    # @return   [Array]
    #
    def neighbours
        @neighbours.to_a
    end

    #
    # Returns node specific info:
    # * Bandwidth Pipe ID
    # * Weight
    # * Nickname
    # * Cost
    #
    # @return    [Hash]
    #
    def node_info
        return unnil({
            :pipe_id    => @opts.pipe_id,
            :weight     => @opts.weight,
            :nickname   => @opts.nickname,
            :cost       => @opts.cost
        })
    end

    private

    #
    # Announces the node to the ones in the peer list
    #
    # @param    [String]    node    URL
    #
    def announce( node )
        print_status 'Advertising: ' + node
        neighbours.each {
            |peer|
            next if peer == node
            print_info '---- to: ' + peer
            connect_to_peer( peer ).node.add_neighbour( node )
        }
        print_status 'Done advertising.'
    end

    #
    # Grabs peers from the node in 'url'.
    #
    # @param    [String]    url     node URL
    #
    def get_peers( url )
        return connect_to_peer( url ).node.neighbours
    end

    def connect_to_peer( url )
        @peer_conn_cache[url] ||=
            Arachni::RPC::XML::Client::Dispatcher.new( @opts, url )
    end

end

end

end
end
end
end
