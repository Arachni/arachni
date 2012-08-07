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

require Options.instance.dir['lib'] + 'component/options'

module Component

#
# Handles modules, reports, path extractor modules, plug-ins, pretty much
# every modular aspect of the framework.
#
# It is usually extended to fill-in for system specific functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Manager < Hash
    include Arachni::UI::Output

    class InvalidOptions < RuntimeError
    end

    #
    # The following are used by {#parse}:
    #    * '*' means all modules
    #    * module names prefixed with '-' will be excluded
    #
    WILDCARD = '*'
    EXCLUDE  = '-'

    attr_reader :lib
    attr_reader :namespace

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
    def load( *components )
        parse( [components].flatten ).each { |component| self.[]( component ) }
    end

    def load_all
        load '*'
    end

    #
    # Loads components by tags.
    #
    # @param    [Array] tags    tags to look for in components
    #
    # @return   [Array] components loaded
    #
    def load_by_tags( tags )
        return [] if !tags

        tags = [tags].flatten.compact.map( &:to_s )
        return [] if tags.empty?

        load( '*' )
        map do |k, v|
            component_tags  = [v.info[:tags]]
            component_tags |= [v.info[:issue][:tags]] if v.info[:issue]
            component_tags  = [component_tags].flatten.uniq.compact

            if !component_tags.includes_tags?( tags )
                delete( k )
                next
            end
            k
        end.compact
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
        options = {}
        errors  = {}
        info[:options].each do |opt|
            name = opt.name
            val  = user_opts[name] || opt.default

            if opt.empty_required_value?( val )
                errors[name] = {
                    opt:   opt,
                    value: val,
                    type:  :empty_required_value
                }
            elsif !opt.valid?( val )
                errors[name] = {
                    opt:   opt,
                    value: val,
                    type:  :invalid
                }
            end

            options[name] = opt.normalize( val )
        end

        if !errors.empty?
            raise InvalidOptions.new( format_error_string( component_name, errors ) )
        end

        options
    end

    #
    # It parses the component array making sure that its structure is valid
    # and takes into consideration wildcards and exclusion modifiers.
    #
    # @param    [Array]    components   array of component names
    #
    # @return   [Array]    array of modules to load
    #
    def parse( components )
        unload = []
        load   = []

        components = [components].flatten.map( &:to_s )

        return load if components[0] == EXCLUDE

        components.each do |component|
            if component[0] == EXCLUDE
                component[0] = ''

                if component[WILDCARD]
                    unload |= wilcard_to_names( component )
                else
                    unload << component
                end

            end
        end

        if !components.include?( WILDCARD )

            avail_components  = available(  )

            components.each do |component|

                if component.substring?( WILDCARD )
                    load |= wilcard_to_names( component )
                else

                    if avail_components.include?( component )
                        load << component
                    else
                        raise( Arachni::Exceptions::ComponentNotFound,
                            "Component '#{component}' could not be found." )
                    end
                end
            end

            load.flatten!
        else
            available.each{ |component| load << component }
        end

        load - unload
    end

    #
    # Returns a component class object by name, loading it on the fly need be.
    #
    # @param    [String]    name    component name
    #
    # @return   [Class]
    #
    def []( name )
        name = name.to_s
        return fetch( name ) if include?( name )
        self[name] = load_from_path( name_to_path( name ) )
    end

    def clear
        keys.each { |l| delete( l ) }
    end

    def delete( k )
        k = k.to_s
        begin
            @namespace.send( :remove_const, fetch( k ).to_s.split( ':' ).last.to_sym )
        rescue
        end
        super( k )
    end
    alias :unload :delete

    #
    # Returns array of available component names.
    #
    # @return    [Array]
    #
    def available
        paths.map{ |path| path_to_name( path ) }
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
        paths.each { |path| return path if name.to_s == path_to_name( path ) }
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
        Dir.glob( File.join( "#{@lib}**", "*.rb" ) ).reject{ |path| helper?( path ) }
    end

    private

    def wilcard_to_names( name )
        if name[WILDCARD]
            paths.map do |path|
                path_to_name( path ) if path.match( name.gsub( '*', '(.*)' ) )
            end.compact
        end
    end

    def format_error_string( name, errors )
        #print_line
        #print_line
        #
        #print_error( "Invalid options for component: #{name}" )
        #
        #errors.each do |optname, error|
        #    val = error[:value].nil? ? '<empty>' : error[:value]
        #    msg = (error[:type] == :invalid) ? "Invalid type" : "Empty required value"
        #
        #    print_error( " *  #{msg}: #{optname} => #{val}" )
        #    print_error( " *  Expected type: #{error[:opt].type}" )
        #    print_line
        #end

        "Invalid options for component: #{name}\n" +
        errors.map do |optname, error|
            val = error[:value].nil? ? '<empty>' : error[:value]
            msg = (error[:type] == :invalid) ? "Invalid type" : "Empty required value"

            " *  #{msg}: #{optname} => #{val}\n" +
            " *  Expected type: #{error[:opt].type}"
        end.join( "\n\n" )
    end

    def load_from_path( path )
        pre = classes
        ::Kernel::load( path )
        post = classes

        return if pre == post
        get_obj( (post - pre).first )
    end

    def classes
        @namespace.constants.reject{ |c| !get_obj( c ).is_a?( Class ) }
    end

    def get_obj( sym )
        @namespace.const_get( sym )
    end

    def helper?( path )
        File.exist?( File.dirname( path ) + '.rb' )
    end

end

end
end
