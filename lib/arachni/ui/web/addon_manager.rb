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

module Arachni
module UI
module Web

module Addons

    #
    # Base class for all add-ons.
    #
    #
    # @author Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #
    # @version 0.1
    #
    class Base

        def initialize( settings, route )
            @settings = settings
            @route    = '/addons/' + route

            @settings.helpers do

                def present( tpl, args )
                    views = current_addon.path_views
                    trv = ( '../' * views.split( '/' ).size ) + views + tpl.to_s

                    erb_args = []
                    erb_args << { :layout => true }
                    erb_args << { :tpl => trv.to_sym, :addon => addons.by_name( current_addon_name ), :tpl_args => args }

                    erb :addon, *erb_args
                end

                def async_present( *args )
                    body present( *args )
                end

                def partial( tpl, args )
                    views = current_addon.path_views
                    trv = ( '../' * views.split( '/' ).size ) + views + tpl.to_s

                    erb_args = []
                    erb_args << { :layout => false }
                    erb_args << args

                    erb trv.to_sym, *erb_args
                end

                def current_addon_name
                    env['PATH_INFO'].scan( /\/addons\/(.*?)\// ).flatten[0]
                end

                def current_addon
                    addons.running[current_addon_name]
                end

            end

        end

        def path_root
            @route
        end

        def path_views
            path_addon + '/views/'
        end

        def path_addon
            Options.instance.dir['lib'] + 'ui/web' + path_root
        end

        def run

        end

        #
        # This optional method allows you to specify the title which will be
        # used for the menu (in case you want it to be dynamic).
        #
        # @return   [String]
        #
        def title
            ''
        end


        #
        #
        # *DO NOT MESS WITH THE FOLLOWING METHODS*
        #
        #


        def settings
           @settings
        end

        def get( path, &block )
            settings.get( @route + path, &block )
        end

        def aget( path, &block )
            settings.aget( @route + path, &block )
        end

        def post( path, &block )
            settings.post( @route + path, &block )
        end

        def apost( path, &block )
            settings.apost( @route + path, &block )
        end

        def put( path, &block )
            settings.put( @route + path, &block )
        end

        def aput( path, &block )
            settings.aput( @route + path, &block )
        end

        def delete( path, &block )
            settings.delete( @route + path, &block )
        end

        def adelete( path, &block )
            settings.adelete( @route + path, &block )
        end

    end
end


#
# Add-on manager.
#
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#
# @version 0.1
#
class AddonManager

    include Utilities

    class Addon
        include DataMapper::Resource

        property :id,   Serial
        property :name, String
    end

    class RestrictedComponentManager < Arachni::Component::Manager
        def paths
            cpaths = paths = Dir.glob( File.join( "#{@lib}", "*.rb" ) )
            return paths.reject { |path| helper?( path ) }
        end
    end

    def initialize( opts, settings )
        @opts     = opts
        @settings = settings

        lib = @opts.dir['lib'] + 'ui/web/addons/'
        @@manager ||= RestrictedComponentManager.new( lib, Addons )

        @@running ||= {}

        DataMapper::setup( :default, "sqlite3://#{@settings.db}/default.db" )
        DataMapper.finalize

        Addon.auto_upgrade!

        run( enabled )
    end

    #
    # Runs addons.
    #
    # @param    [Array]     addons  array holding the names of the addons
    #
    def run( addons )

        begin
            addons.each {
                |name|
                @@running[name] = @@manager[name].new( @settings, name )
                @@running[name].run
            }

        rescue ::Exception => e
            # ap e.to_s
            # ap e.backtrace
        end
    end

    def running
        @@running
    end

    #
    # Gets add-on info by name.
    #
    # @param    [String]    name
    #
    # @return   [Hash]
    #
    def by_name( name )
        available.each { |addon| return addon if addon['filename'] == name }
        return nil
    end

    #
    # Gets all available add-ons.
    #
    # @return   [Array]
    #
    def available
        @@available ||= populate_available

        @@available.each {
            |addon|

            if @@running[addon['filename']] && !@@running[addon['filename']].title.empty?
                addon['title'] = @@running[addon['filename']].title
            else
                addon['title'] = addon['name']
            end
        }

        return @@available
    end

    #
    # Enables and runs add-ons.
    #
    # @param    [Array]     addons  array holding the names of the addons
    #
    def enable!( addons )
        Addon.all.destroy
        addons.each { |addon| Addon.create( :name => addon ); run( [addon] ) }
    end

    #
    # Gets all enabled add-ons.
    #
    # @return   [Array]
    #
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
