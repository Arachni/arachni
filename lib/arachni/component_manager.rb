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

require Options.instance.dir['lib'] + 'component_options'

#
# Component Manager
#
# Handles modules, reports, path extrator modules, plug-ins, pretty much
# every modular aspect of the framework.
#
# It is usually extended to fill-in for system specific functionality.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#
# @version 0.1
#
class ComponentManager < Hash

    include Arachni::UI::Output


    #
    # The following are used by {#parse}:
    #    * '*' means all modules
    #    * module names prefixed with '-' will be excluded
    #
    WILDCARD = '*'
    EXCLUDE  = '-'

    #
    # @param    [String]    lib       the path to the component library/folder
    # @param    [Module]    namespace    the namespace of the components
    #
    def initialize( lib, namespace )
        @lib    = lib
        @namespace = namespace
    end

    #
    # Loads components.
    #
    # @param    [Array]    components    array of names of components to load
    #
    def load( components )
        parse( [components].flatten ).each {
            |component|
            self.[]( component )
        }
    end

    #
    # Validates and prepares options for a given component.
    #
    # @param    [String]    component_name    the name of the component
    # @param    [Class]     component         the component
    # @param    [Hash]      user_opts         the user options
    #
    # @return   [Hash]   the prepared options to be passed to the component
    #
    def prep_opts( component_name, component, user_opts = {} )
        info = component.info
        return {} if !info.include?( :options ) || info[:options].empty?

        user_opts ||= {}
        options = { }
        errors  = { }
        info[:options].each {
            |opt|

            name  = opt.name
            val   = user_opts[name] || opt.default

            if( opt.empty_required_value?( val ) )
                errors[name] = {
                    :opt   => opt,
                    :value => val,
                    :type  => :empty_required_value
                }
            elsif( !opt.valid?( val ) )
                errors[name] = {
                    :opt   => opt,
                    :value => val,
                    :type  => :invalid
                }
            end

            val = !val.nil? ? val : opt.default
            options[name] = opt.normalize( val )
        }

        if( !errors.empty? )
            print_errors( component_name, errors )
        end

        return options
    end


    #
    # It parses the component array making sure that its structure is valid
    #
    # @param    [Array]    components   array of component names
    #
    # @return   [Array]    array of modules to load
    #
    def parse( components )
        unload = []
        load   = []

        return load if components[0] == EXCLUDE

        components.each {
            |component|
            if component[0] == EXCLUDE
                component[0] = ''

                if component[WILDCARD]
                    unload |= wilcard_to_names( component )
                else
                    unload << component
                end

            end
        }

        if( !components.include?( WILDCARD ) )

            avail_components  = available(  )

            components.each {
                |component|

                if component.substring?( WILDCARD )
                    load |= wilcard_to_names( component )
                else

                    if( avail_components.include?( component ) )
                        load << component
                    else
                        raise( Arachni::Exceptions::ComponentNotFound,
                            "Error: Component #{component} wasn't found." )
                    end
                end

            }
            load.flatten!

        else
            available(  ).map {
                |component|
                load << component
            }
        end

        return load - unload
    end

    #
    # Returns a component class object by name, loading it on the fly need be.
    #
    # @param    [String]    name    component name
    #
    # @return   [Class]
    #
    def []( name )

        return fetch( name ) if include?( name )

        paths.each {
            |path|

            next if name != path_to_name( path )
            self[path_to_name( path )] = load_from_path( path )
        }

        return fetch( name ) rescue nil
    end

    def wilcard_to_names( name )
        if name[WILDCARD]
            return paths.map {
                |path|
                path_to_name( path ) if path.match( Regexp.new( name ) )
            }.compact
        end

        return
    end

    def delete( k )
        @namespace.send( :remove_const, self[k].to_s.split( ':' ).last.to_sym )
        super( k )
    end

    #
    # Returns array of available component names.
    #
    # @return    [Array]
    #
    def available
        components = []
        paths.each {
            |path|
            name = path_to_name( path )
            components << name
        }
        return components
    end

    #
    # Returns array of loaded component names.
    #
    # @return    [Array]
    #
    def loaded
        keys
    end

    #
    # Converts the name of a component to a file-path.
    #
    # @param    [String]    name    the name of the component
    #
    # @return   [String]
    #
    def name_to_path( name )
        paths.each {
            |path|
            return path if name == path_to_name( path )
        }
        return
    end

    #
    # Converts the path of a component to a component name.
    #
    # @param    [String]    path    the file-path of the component
    #
    # @return   [String]
    #
    def path_to_name( path )
        File.basename( path, '.rb' )
    end

    #
    # Returns the paths of all available components (excluding helper files).
    #
    # @return   [Array]
    #
    def paths
        cpaths = paths = Dir.glob( File.join( "#{@lib}**", "*.rb" ) )
        return paths.reject { |path| helper?( path ) }
    end

    private

    def print_errors( name, errors )

        print_line
        print_line

        print_error( "Invalid options for component: #{name}" )

        errors.each {
            |optname, error|

            val = error[:value].nil? ? '<empty>' : error[:value]

            if( error[:type] == :invalid )
                msg = "Invalid type"
            else
                msg = "Empty required value"
            end

            print_error( " *  #{msg}: #{optname} => #{val}" )
            print_error( " *  Expected type: #{error[:opt].type}" )

            print_line
        }

        exit
    end

    def load_from_path( path )
        ::Kernel::load( path )
        return @namespace.const_get( @namespace.constants[-1] )
    end


    def helper?( path )
        return File.exist?( File.dirname( path ) + '.rb' )
    end

end

end
