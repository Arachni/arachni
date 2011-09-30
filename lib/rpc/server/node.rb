=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end


module Arachni

require Options.instance.dir['lib'] + 'rpc/server/output'

module RPC
class Server

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

        @dead_nodes = []
        @neighbours = Set.new
        @nodes_info_cache = []

        if neighbour = @opts.neighbour
            add_neighbour( neighbour )

            peer = connect_to_peer( neighbour )
            peer.node.neighbours {
                |urls|
                urls.each {
                    |url|
                    @neighbours << url if url != @opts.datastore[:dispatcher_url]
                }
            }

            peer.node.add_neighbour( @opts.datastore[:dispatcher_url], true ){
                |res|

                if res.rpc_exception?
                    print_info( 'Neighbour seems dead: ' + neighbour )
                    remove_neighbour( neighbour )
                end
            }
        end

        print_status( 'Node ready.' )

        log_updated_neighbours

        ::EM.add_periodic_timer( 60 ) {
            ::EM.defer {
                ping
                check_for_comebacks
            }
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
        log_updated_neighbours
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

    def remove_neighbour( node_url )
        @neighbours -= [node_url]
        @dead_nodes << node_url
    end

    def neighbours_with_info( &block )
        raise( "This method requires a block!" ) if !block_given?

        @neighbours_cmp = ''
        if @nodes_info_cache.empty? || @neighbours_cmp != neighbours.to_s

            @neighbours_cmp = neighbours.to_s

            ::EM::Iterator.new( neighbours ).map( proc {
                |neighbour, iter|

                connect_to_peer( neighbour ).node.info {
                    |info|

                    if info.rpc_exception?
                        print_info( 'Neighbour seems dead: ' + neighbour )
                        remove_neighbour( neighbour )
                        log_updated_neighbours

                        iter.return( nil )
                    else
                        iter.return( info )
                    end
                }
            }, proc {
                |nodes|
                @nodes_info_cache = nodes.compact
                block.call( @nodes_info_cache )
            })
        else
            block.call( @nodes_info_cache )
        end
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
    def info
        return {
            'url'        => @opts.datastore[:dispatcher_url],
            'pipe_id'    => @opts.pipe_id,
            'weight'     => @opts.weight,
            'nickname'   => @opts.nickname,
            'cost'       => @opts.cost
        }
    end

    private

    def log_updated_neighbours
        print_info 'Updated neighbours:'

        if !neighbours.empty?
            neighbours.each {
                |node|
                print_info( '---- ' + node )
            }
        else
            print_info( '<empty>' )
        end
    end

    def ping
        neighbours.each {
            |neighbour|
            connect_to_peer( neighbour ).alive? {
                |res|
                if res.rpc_exception?
                    remove_neighbour( neighbour )
                    print_status( "Found dead neighbour: #{neighbour} " )
                end
            }
        }
    end

    def check_for_comebacks
        d_nodes = @dead_nodes.dup
        d_nodes.each {
            |url|
            neighbour = connect_to_peer( url )
            neighbour.alive? {
                |res|
                if !res.rpc_exception?
                    print_status( 'Dispatcher came back to life: ' + url )

                    ([@opts.datastore[:dispatcher_url]] | neighbours ).each {
                        |node|
                        neighbour.node.add_neighbour( node ){}
                    }

                    add_neighbour( url )
                    @dead_nodes -= [url]
                end
            }
        }
    end

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
            connect_to_peer( peer ).node.add_neighbour( node ) {
                |res|
                if res.rpc_exception?
                    remove_neighbour( peer )
                end
            }
        }

    end

    def connect_to_peer( url )
        Arachni::RPC::Client::Dispatcher.new( @opts, url )
    end

end

end

end
end
end
