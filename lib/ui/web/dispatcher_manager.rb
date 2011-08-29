=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'datamapper'

module Arachni
module UI
module Web

#
# Provides methods for dispatcher management.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
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

        begin
            connect( url ).node.neighbours_with_info.each {
                |node|
                Dispatcher.first_or_create( :url => node['url'] )
            }
        rescue Exception => e
            ap e
            ap e.backtrace
        end
    end

    #
    # Provides an easy way to connect to a dispatcher and caches connections
    # to reduce overhead.
    #
    # @param    [String]   url
    #
    # @return   [Arachni::RPC::XML::Client::Dispatcher]
    #
    def connect( url )
        @@cache ||= {}

        begin
            if @@cache[url] && @@cache[url].alive?
                return @@cache[url]
            elsif ( tmp = Arachni::RPC::XML::Client::Dispatcher.new( @opts, url ) ) &&
                  tmp.alive?
                return @@cache[url] = tmp
            end
        rescue Exception => e
            # ap e
            # ap e.backtrace
            return nil
        end
    end

    #
    # Checks wether the dispatcher is alive.
    #
    # @param    [String]    url     URL of the dispatcher
    #
    def alive?( url, tries = 5 )
        tries.times {
            begin
                return connect( url ).alive?
            rescue Exception => e
                # ap e
                # ap e.backtrace
            end
        }

        return false
    end

    def first_alive
        all.each {
            |dispatcher|
            return dispatcher if alive?( dispatcher.url )
        }

        return nil
    end

    #
    # Provides statistics about running jobs etc using the dispatcher
    #
    # @return   [Hash]
    #
    def stats
        stats_h = {}
        all.each {
            |dispatcher|

            begin
                stats_h[dispatcher['url']] = connect( dispatcher['url'] ).stats
                stats_h[dispatcher['url']]['running_jobs'].each {
                    |job|
                    begin
                        instance = @settings.instances.port_to_url( job['port'], dispatcher['url'] )
                        job['paused'] = @settings.instances.connect( instance ).framework.paused?
                    rescue
                    end
                }
            rescue
            end
        }

        return stats_h
    end

    #
    # Returns all dispatchers stored in the DB.
    #
    # @return    [Array]
    #
    def all( *args )
        Dispatcher.all( *args )
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
