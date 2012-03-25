=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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

require 'socket'

require Arachni::Options.instance.dir['lib'] + 'rpc/client/dispatcher'

module Arachni
module UI
module Web

#
# Provides methods for dispatcher management.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.1.1
#
class DispatcherManager

    class Dispatcher
        include DataMapper::Resource

        property :id,           Serial
        property :url,          String
    end


    def initialize( opts, settings )
        @opts     = opts
        @settings = settings

        DataMapper::setup( :default, "sqlite3://#{@settings.db}/default.db" )
        DataMapper.finalize

        Dispatcher.auto_upgrade!
    end

    #
    # Puts a new dispatcher (and it's neighbours) in the DB.
    #
    # @param    [String]    url          URL of the dispatcher
    # @param    [Bool]      neighbours   add its neighbouring dispatchers too?
    #
    def new( url, neighbours = true )
        Dispatcher.first_or_create( :url => url )

        return if !neighbours
        connect( url ).node.neighbours {
            |neighbours|
            neighbours.each {
                |node|
                Dispatcher.first_or_create( :url => node )
            }
        }
    end

    #
    # Provides an easy way to connect to a dispatcher.
    #
    # @param    [String]   url
    #
    # @return   [Arachni::RPC::Client::Dispatcher]
    #
    def connect( url )
        Arachni::RPC::Client::Dispatcher.new( @opts, url )
    end

    #
    # Checks wether the dispatcher is alive.
    #
    # @param    [String]    url     URL of the dispatcher
    #
    def alive?( url, &block )
        raise( "This method requires a block!" ) if !block_given?

        connect( url ).alive? {
            |ret|
            block.call( ret.rpc_connection_error? ? false : true )
        }
    end

    def first_alive( &block )
        raise( "This method requires a block!" ) if !block_given?

        if !all.empty?
            EM.synchrony do
                dispatchers = EM::Synchrony::Iterator.new( all ).map {
                    |dispatcher, iter|
                    alive?( dispatcher.url ){
                        |bool|
                        if bool
                            iter.return( dispatcher )
                        else
                            iter.return( nil )
                        end
                    }
                }.compact

                if dispatchers.empty?
                    block.call( false )
                else
                    block.call( dispatchers.pop )
                end
            end
        else
            block.call( false )
        end
    end

    def jobs( &block )
        ::EM::Iterator.new( all, 20 ).map( proc {
            |dispatcher, iter|

            connect( dispatcher.url ).stats {
                |stats|
                iter.return( stats['running_jobs'] ) if !stats.rpc_connection_error?
            }

        }, proc {
            |running|
            block.call( running.flatten )
        })
    end

    #
    # Provides statistics about running jobs etc using the dispatcher
    #
    # @return   [Hash]
    #
    def stats( &block )
        raise( "This method requires a block!" ) if !block_given?

        EM.synchrony do

            stats = EM::Synchrony::Iterator.new( all ).map {
                |dispatcher, iter|

                if !dispatcher.rpc_connection_error?
                    connect( dispatcher.url ).stats {
                        |stats|
                        if !stats.rpc_exception?

                            # automatically grab and save neighbours
                            stats['neighbours'].each { |n| new( n ) }

                            iter.return( { dispatcher.url => stats } )
                        else
                            iter.return( nil )
                        end
                    }
                end
            }.compact

            sorted_stats = {}
            stats.sort{ |a, b| a.keys[0] <=> b.keys[0] }.each {
                |stat|
                sorted_stats.merge!( stat )
            }

            sorted_stats.each_pair {
                |k, stats|

                sorted_stats[k]['running_jobs'] =
                    EM::Synchrony::Iterator.new( stats['running_jobs'] ).map {
                    |instance, iter|

                    if instance['helpers']['rank'] != 'slave'
                        @settings.instances.connect( instance['url'] ).framework.progress_data(
                            :slaves   => false,
                            :messages => false,
                            :issues   => false
                        ) {
                            |prog_data|
                            if prog_data.rpc_exception?
                                iter.return( nil )
                            else
                                instance.merge!( prog_data['stats'] )
                                instance['status']  = prog_data['status'].capitalize!
                                iter.return( instance )
                            end
                        }
                    else
                        @settings.instances.connect( instance['helpers']['master'] ).framework.progress_data(
                            :messages => false,
                            :issues   => false
                        ) {
                            |prog_data|
                            if prog_data.rpc_exception?
                                iter.return( nil )
                            else
                                prog_data['instances'].each {
                                    |insdat|
                                     if insdat['url'] == instance['url']
                                         instance.merge!( insdat )
                                         instance['status'].capitalize!
                                         iter.return( instance )
                                    end
                                }
                            end
                        }
                    end
                }.compact
            }

            block.call( sorted_stats )
        end
    end

    #
    # Returns all dispatchers stored in the DB.
    #
    # @return    [Array]
    #
    def all( *args )
        Dispatcher.all( *args )
    end

    def all_with_liveness( &block )
        raise( "This method requires a block!" ) if !block_given?

        EM::Iterator.new( all ).map( proc{
            |dispatcher, iter|

            alive?( dispatcher.url ) {
                |liveness|

                m_dispatcher = {}
                dispatcher.attributes.each_pair {
                    |k, v|
                    m_dispatcher[k.to_s] = v
                }
                m_dispatcher['alive'] = liveness
                iter.return( m_dispatcher )
            }
        }, proc{
            |dispatchers|
            block.call( dispatchers )
        })
    end

    #
    # Removed all dispatchers from the DB.
    #
    def delete_all
        all.each {
            |report|
            delete( report.id )
        }
        all.destroy
    end

    #
    # Removed a dispatcher from the DB.
    #
    # @param    [Integer]   id
    #
    def delete( id )
        Dispatcher.get( id ).destroy
    end

end
end
end
end
