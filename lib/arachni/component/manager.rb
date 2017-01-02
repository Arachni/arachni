=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

module Component

# {Component} error namespace.
#
# All {Component} errors inherit from and live under it.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Error < Arachni::Error

    # Raised when a specified component could not be found/does not exist.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class NotFound < Error
    end
end

require Options.paths.lib + 'component/options'

# Handles checks, reports, path extractor checks, plug-ins, pretty much
# every modular aspect of the framework.
#
# It is usually extended to fill-in for system specific functionality.
#
# @example
#
#    # create a namespace for our components
#    module Components
#    end
#
#    LIB       = "#{File.dirname( __FILE__ )}/lib/"
#    NAMESPACE = Components
#
#    # $ ls LIB
#    #   component1.rb  component2.rb
#    #
#    # $ cat LIB/component1.rb
#    #   class Components::Component1
#    #   end
#    #
#    # $ cat LIB/component2.rb
#    #   class Components::Component2
#    #   end
#
#
#    p components = Arachni::Component::Manager.new( LIB, NAMESPACE )
#    #=> {}
#
#    p components.available
#    #=> ["component2", "component1"]
#
#    p components.load_all
#    #=> ["component2", "component1"]
#
#    p components
#    #=> {"component2"=>Components::Component2, "component1"=>Components::Component1}
#
#    p components.clear
#    #=> {}
#
#    p components.load :component1
#    #=> ["component1"]
#
#    p components
#    #=> {"component1"=>Components::Component1}
#
#    p components.clear
#    #=> {}
#
#    p components[:component2]
#    #=> Components::Component2
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Manager < Hash
    include UI::Output
    include Utilities
    extend  Utilities

    WILDCARD = '*'
    EXCLUDE  = '-'

    # @return   [String]
    #   The path to the component library/directory.
    attr_reader :lib

    # @return [Module]
    #   Namespace under which all components are directly defined.
    attr_reader :namespace

    # @param    [String]    lib
    #   The path to the component library/directory.
    # @param    [Module,Class]    namespace
    #   Namespace under which all components are directly defined.
    def initialize( lib, namespace )
        @lib       = lib
        @namespace = namespace

        @helper_check_cache = {}
        @name_to_path_cache = {}
        @path_to_name_cache = {}
    end

    # Loads components.
    #
    # @param    [Array<String,Symbol>]    components
    #   Components to load.
    #
    # @return   [Array]
    #   Names of loaded components.
    def load( *components )
        parse( [components].flatten ).each { |component| self.[]( component ) }
    end

    # Loads all components, equivalent of `load '*'`.
    #
    # @return   [Array]
    #   Names of loaded components.
    def load_all
        load '*'
    end

    # Loads components by the tags found in the `Hash` returned by their `.info`
    # method (tags should be in either: `:tags` or `:issue[:tags]`).
    #
    # @param    [Array] tags
    #   Tags to look for in components.
    #
    # @return   [Array]
    #   Components loaded.
    def load_by_tags( tags )
        return [] if !tags

        tags = [tags].flatten.compact.map( &:to_s )
        return [] if tags.empty?

        load_all
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

    # Validates and prepares options for a given component.
    #
    # @param    [String]    component_name
    #   Name of the component.
    # @param    [Component::Base]     component
    #   Component.
    # @param    [Hash]      user_opts
    #   User options.
    #
    # @return   [Hash]
    #   Prepared options to be passed to the component.
    #
    # @raise    [Component::Options::Error::Invalid]
    #   If given options are invalid.
    def prepare_options( component_name, component, user_opts = {} )
        info = component.info
        return {} if !info.include?( :options ) || info[:options].empty?

        user_opts ||= {}
        user_opts   = user_opts.my_symbolize_keys(false)

        options     = {}
        errors      = {}
        info[:options].each do |option|
            option.value = user_opts[option.name]

            if option.missing_value?
                errors[option.name] = {
                    option: option,
                    value:  option.value,
                    type:   :missing_value
                }

                break
            end

            next if option.effective_value.nil?

            if !option.valid?
                errors[option.name] = {
                    option: option,
                    value:  option.value,
                    type:   :invalid
                }

                break
            end

            options.merge! option.for_component
        end

        if !errors.empty?
            fail Component::Options::Error::Invalid,
                 format_error_string( component_name, errors )
        end

        options.my_symbolize_keys( false )
    end

    # It parses the component array making sure that its structure is valid
    # and takes into consideration {WILDCARD wildcard} and {EXCLUDE exclusion}
    # modifiers.
    #
    # @param    [Array<String,Symbol>]    components
    #   Component names.
    #
    # @return   [Array]
    #   Components to load.
    def parse( components )
        unload = []
        load   = []

        components = [components].flatten.map( &:to_s )

        return load if components[0] == EXCLUDE

        components = components.deep_clone

        components.each do |component|
            if component[0] == EXCLUDE
                component[0] = ''

                if component[WILDCARD]
                    unload |= glob_to_names( component )
                else
                    unload << component
                end

            end
        end

        if !components.include?( WILDCARD )

            avail_components  = available(  )

            components.each do |component|

                if component.include?( WILDCARD )
                    load |= glob_to_names( component )
                else

                    if avail_components.include?( component )
                        load << component
                    else
                        fail Error::NotFound,
                             "Component '#{component}' could not be found."
                    end
                end
            end

            load.flatten!
        else
            available.each{ |component| load << component }
        end

        load - unload
    end

    # Fetches a component's class by name, loading it on the fly if need be.
    #
    # @param    [String, Symbol]    name
    #   Component name.
    #
    # @return   [Component::Base]
    #   Component.
    def []( name )
        name = name.to_s
        return fetch( name ) if include?( name )
        self[name] = load_from_path( name_to_path( name ) )
    end

    def include?( k )
        super( k.to_s )
    end
    alias :loaded? :include?

    # Unloads all loaded components.
    def clear
        keys.each { |l| delete( l ) }
    end
    alias :unload_all :clear

    # Unloads a component by name.
    #
    # @param    [String, Symbol]    name
    #   Component name.
    def delete( name )
        name = name.to_s
        begin
            @namespace.send(
                :remove_const,
                fetch( name ).to_s.split( ':' ).last.to_sym
            )
        rescue
        end

        super( name )
    end
    alias :unload :delete

    # @return    [Array]
    #   Names of available components.
    def available
        paths.map { |path| path_to_name( path ) }
    end

    # @return    [Array]
    #   Names of loaded components.
    def loaded
        keys
    end

    # Converts the name of a component to a its file's path.
    #
    # @param    [String]    name
    #   Name of the component.
    #
    # @return   [String]
    #   Path to component file.
    def name_to_path( name )
        @name_to_path_cache[name] ||=
            paths.find { |path| name.to_s == path_to_name( path ) }
    end

    # Converts the path of a component to a component name.
    #
    # @param    [String]    path
    #   File-path of the component.
    #
    # @return   [String]
    #   Component name.
    def path_to_name( path )
        @path_to_name_cache[path] ||= File.basename( path, '.rb' )
    end

    # @return   [Array]
    #   Paths of all available components (excluding helper files).
    def paths
        @paths_cache ||=
            Dir.glob( File.join( "#{@lib}**", "*.rb" ) ).
                reject{ |path| helper?( path ) }
    end

    def matches_globs?( path, globs )
        !![globs].flatten.compact.find { |glob| matches_glob?( path, glob ) }
    end

    def matches_glob?( path, glob )
        relative_path = File.dirname( path.gsub( @lib, '' ) )
        relative_path << '/' if !relative_path.end_with?( '/' )

        name = path_to_name( path )

        Support::Glob.new( glob ) =~ name ||
            Support::Glob.new( glob ) =~ relative_path
    end

    private

    def glob_to_names( glob )
        if glob[WILDCARD]
            paths.map do |path|
                next if !matches_glob?( path, glob )

                path_to_name( path )
            end.compact
        end
    end

    def format_error_string( name, errors )
        "Invalid options for component: #{name}\n" +
        errors.map do |optname, error|
            val = error[:value].nil? ? '<empty>' : error[:value]
            msg = (error[:type] == :invalid) ? 'Invalid type' : 'Missing value'

            " *  #{msg}: #{optname} => '#{val}'\n" +
            " *  Expected type: #{error[:option].type}"
        end.join( "\n\n" )
    end

    def load_from_path( path )
        pre = classes
        ::Kernel::load( path )
        post = classes

        return if pre == post

        get_obj( (post - pre).first ).tap do |component|
            next if !component.respond_to?( :shortname= )
            component.shortname = path_to_name( path )
        end
    end

    def classes
        @namespace.constants.reject{ |c| !get_obj( c ).is_a?( Class ) }
    end

    def get_obj( sym )
        @namespace.const_get( sym )
    end

    def helper?( path )
        @helper_check_cache[path] ||= File.exist?( File.dirname( path ) + '.rb' )
    end

end

end
end
