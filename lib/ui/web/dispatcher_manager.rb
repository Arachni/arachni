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
#
# Provides nice little wrapper for the Arachni::Report::Manager while also handling<br/>
# conversions, storing etc.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
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

    def new( opts )
        Dispatcher.create( :url => opts[:url] )
    end

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
          return nil
        end
    end

    def alive?( url )
        begin
            return connect( url ).alive?
        rescue
            return false
        end
    end

    #
    # Returns the paths of all saved report files as an array
    #
    # @return    [Array]
    #
    def all( *args )
        Dispatcher.all( *args )
    end

    def delete_all
        all.each {
            |report|
            delete( report.id )
        }
        all.destroy
    end

    def delete( id )
        Dispatcher.get( id ).destroy
    end

end
end
end
end
