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

        if neighbour = @opts.neighbour
            add_neighbour( neighbour )

            get_peers( neighbour ).each {
                |url|
                @neighbours << url if url != @opts.datastore[:dispatcher_url]
            }

            begin
                pp peer = connect_to_peer( neighbour )
                peer.node.add_neighbour( opts.datastore[:dispatcher_url], true )
            rescue Exception => e
                ap e
                print_info( 'Neighbour seems dead: ' + neighbour )
                remove_neighbour( neighbour )
                log_updated_neighbours
            end
        end

        print_status( 'Node ready.' )

        log_updated_neighbours
        @nodes_info_cache = []

        @dead_nodes = []

        Thread.new {
            while( true )
                ping
                check_for_comebacks
                sleep( 60 )
            end
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

    def neighbours_with_info
        @neighbours_cmp = ''
        if @nodes_info_cache.empty? || @neighbours_cmp != neighbours.to_s

            @neighbours_cmp = neighbours.to_s

            return @nodes_info_cache = neighbours.map {
                |neighbour|
                begin
                    connect_to_peer( neighbour ).node.info
                rescue Errno::ECONNREFUSED
                    print_info( 'Neighbour seems dead: ' + neighbour )
                    remove_neighbour( neighbour )
                    log_updated_neighbours
                    nil
                end
            }.compact
        else
            return @nodes_info_cache
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
        neighbours.each {
            |node|
            print_info( '---- ' + node )
        }
    end

    def ping
        dead = []
        jobs = []
        neighbours.each {
            |neighbour|
            jobs << Thread.new {
                begin
                    connect_to_peer( neighbour ).alive?
                rescue Exception
                    dead << neighbour
                end
            }
        }

        jobs.each { |job| job.join }

        if dead.size > 0
            print_status( "Found #{dead.size} dead neighbours:" )
            dead.each {
                |stiff|
                remove_neighbour( stiff )
                print_info( '---- ' + stiff )
            }

            log_updated_neighbours
        end
    end

    def check_for_comebacks
        alive = []
        jobs = []
        @dead_nodes.each {
            |url|
            jobs << Thread.new {
                begin
                    neighbour = connect_to_peer( url )
                    neighbour.alive?
                    print_status( 'Dispatcher came back to life: ' + url )

                    neighbours.each {
                        |node|
                        begin
                            neighbour.node.add_neighbour( node )
                        rescue
                        end
                    }

                    add_neighbour( url )
                    alive << url
                rescue
                end
            }
        }

        jobs.each { |job| job.join }

        @dead_nodes -= alive
    end

    #
    # Announces the node to the ones in the peer list
    #
    # @param    [String]    node    URL
    #
    def announce( node )
        print_status 'Advertising: ' + node

        jobs = []
        neighbours.each {
            |peer|
            next if peer == node
            jobs << Thread.new {
                begin
                    print_info '---- to: ' + peer
                    connect_to_peer( peer ).node.add_neighbour( node )
                rescue Errno::ECONNREFUSED
                    remove_neighbour( peer )
                end
            }
        }

        jobs.each { |job| job.join }
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
        Arachni::RPC::Client::Dispatcher.new( @opts, url )
    end

end

end

end
end
end
