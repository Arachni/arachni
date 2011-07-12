=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end


module Arachni
module UI
module Web

module Addons
    class Base

        def initialize( settings, route )
            @settings = settings
            @route    = '/addons/' + route

            @settings.helpers do

                def present( *args )
                    file = ::Kernel.caller[0].split( ':' )[0]
                    splits = file.split( '.' )
                    splits.pop
                    file   = splits.join( '.' ) + '/views/'

                    trv = ( '../' * file.split( '/' ).size ) + file + args.shift.to_s
                    erb trv.to_sym, *args
                end

            end

        end

        def run

        end

        def settings
           @settings
        end

        def get( path, &block )
            settings.get( @route + path, &block )
        end

        def post
            settings.post( @route + path, &block )
        end

        def put
            settings.put( @route + path, &block )
        end

        def delete
            settings.delete( @route + path, &block )
        end

    end
end


#
# Add-on manager.
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class AddonManager

    include Utilities

    class Addon
        include DataMapper::Resource

        property :id,   Serial
        property :name, String
    end


    def initialize( opts, settings )
        @opts     = opts
        @settings = settings

        lib = @opts.dir['lib'] + 'ui/web/addons/'
        @@manager ||= ::Arachni::ComponentManager.new( lib, Addons )

        DataMapper::setup( :default, "sqlite3://#{@settings.db}/default.db" )
        DataMapper.finalize

        Addon.auto_upgrade!
    end

    def run( addons )

        begin
            addons.each {
                |name|
                @@manager[name].new( @settings, name ).run
            }

        rescue ::Exception => e
            ap e.to_s
            ap e.backtrace
        end
    end

    def by_name( name )
        @@manager[name].info
    end

    def available
        @@available ||= populate_available
    end

    def enable!( addons )
        Addon.all.destroy
        addons.each { |addon| Addon.create( :name => addon ) }
    end

    def enabled
        Addon.all.map { |addon| addon.name }
    end

    private
    def populate_available
        @@available ||= []
        return @@available if !@@available.empty?

        @@available_classes ||= {}
        @@manager.available.each {
            |avail|

            @@available << {
                'name'        => @@manager[avail].info[:name],
                'filename'    => avail,
                'description' => @@manager[avail].info[:description],
                'version'     => @@manager[avail].info[:version],
                'author'      => @@manager[avail].info[:author]
            }

            @@available_classes[avail] = @@manager[avail]

        }
        return @@available
    end

end
end
end
end
