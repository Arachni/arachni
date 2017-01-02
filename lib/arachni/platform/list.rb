=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

module Platform

# Represents a collection of applicable platforms.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class List
    include Enumerable

    # @param    [Array<String, Symbol>]    valid_platforms
    #   Valid platforms for this list.
    def initialize( valid_platforms )
        @valid_platforms = normalize!( valid_platforms )
        @platforms       = []
    end

    # @return   [Array<Symbol>]
    #   Supported platforms.
    def valid
        hierarchical? ? @valid_platforms.find_symbol_keys_recursively : @valid_platforms
    end

    # Selects appropriate data depending on the applicable platforms
    # from `data_per_platform`.
    #
    # @param    [Hash{<Symbol, String> => Object}]   data_per_platform
    #   Hash with platform names as keys and arbitrary data as values.
    #
    # @return   [Hash]
    #   `data_per_platform` with non-applicable entries removed.
    #
    # @raise    [Error::Invalid]
    #   On {#invalid?} platforms.
    def pick( data_per_platform )
        orig_data_per_platform = data_per_platform.dup
        data_per_platform      = data_per_platform.dup

        data_per_platform.select! { |k, v| include? k }

        # Bail out if the valid platforms are just a flat array, without hierarchy.
        return data_per_platform if !hierarchical?

        # Keep track of parents which will be removed due to the existence of
        # their children.
        specified_parents = []

        # Remove parents if we have children.
        data_per_platform.keys.each do |platform|
            specified_parents |= parents = find_parents( platform )
            data_per_platform.reject! { |k, _| parents.include? k }
        end

        # Include all of the parents' children if parents are specified but no
        # children for them.

        children = {}
        children_for = valid & @platforms.to_a
        children_for.each do |platform|
            next if specified_parents.include? platform
            c = find_children( platform )
            children.merge! orig_data_per_platform.select { |k, _| c.include? k }
        end

        data_per_platform.merge! children

        # Include the nearest parent data there is a child platform but there
        # are no data for it.

        ignore = data_per_platform.keys | specified_parents
        orig_data_per_platform.each do |platform, data|
            next if ignore.include?( platform ) ||
                !include_any?( find_children( platform ) )
            data_per_platform[platform] = data
        end

        data_per_platform
    end

    # @param    [Array<Symbol, String> Symbol, String]  platforms
    #   Platform(s) to check.
    #
    # @return   [Boolean]
    #   `true` if platforms are valid (i.e. in {#valid}), `false` otherwise.
    #
    # @see #invalid?
    def valid?( platforms )
        normalize( platforms )
        true
    rescue
        false
    end

    # @param    [Array<Symbol, String> Symbol, String]  platforms
    #   Platform(s) to check.
    #
    # @return   [Boolean]
    #   `true` if platforms are invalid (i.e. not in {#valid}), `false` otherwise.
    #
    # @see #valid?
    def invalid?( platforms )
        !valid?( platforms )
    end

    # @return   [Boolean]
    #   `true` if there are no applicable platforms, `false` otherwise.
    def empty?
        @platforms.empty?
    end

    # @return   [Boolean]
    #   `true` if there are applicable platforms, `false` otherwise.
    def any?
        !empty?
    end

    # @param    [Symbol, String]    platform
    #   Platform to add to the list.
    #
    # @return   [Platform] `self`
    #
    # @raise    [Error::Invalid]
    #   On {#invalid?} platforms.
    def <<( platform )
        @platforms |= [normalize( platform )]
        self
    end

    # @param    [Platform, Enumerable] enum
    #   Enumerable object containing platforms.
    #   New {Platform} built by merging `self` and the elements of the
    #   given enumerable object.
    #
    # @raise    [Error::Invalid]
    #   On {#invalid?} platforms.
    def merge( enum )
        dup.merge!( enum )
    end
    alias + merge
    alias | merge

    # @param    [Enumerable] enum
    #   Enumerable object containing platforms.
    #
    # @return   [Platform]
    #   Updated `self`.
    #
    # @raise    [Error::Invalid]
    #   On {#invalid?} platforms.
    def merge!( enum )
        @platforms |= normalize( enum )
        self
    end
    alias update merge!

    # @param    [Block] block
    #   Block to be passed each platform.
    #
    # @return   [Enumerator, Platform]
    #   `Enumerator` if no `block` is given, `self` otherwise.
    def each( &block )
        return enum_for( __method__ ) if !block_given?
        @platforms.each( &block )
        self
    end

    # @param    [Symbol, String]    platform
    #   Platform to check.
    #
    # @return   [Boolean]
    #   `true` if `platform` applies to the given resource, `false` otherwise.
    #
    # @raise    [Error::Invalid]
    #   On {#invalid?} `platforms`.
    def include?( platform )
        @platforms.include? normalize( platform )
    end

    # @param    [Array<Symbol, String>]    platforms
    #   Platform to check.
    #
    # @return   [Boolean]
    #   `true` if any platform in `platforms` applies to the given resource,
    #   `false` otherwise.
    #
    # @raise    [Error::Invalid]
    #   On {#invalid?} `platforms`.
    def include_any?( platforms )
        (@platforms & normalize( platforms )).any?
    end

    # Clears platforms.
    def clear
        @platforms.clear
    end

    # @return   [Platform]
    #   Copy of `self`.
    def dup
        self.class.new( @valid_platforms ).tap { |p| p.platforms = @platforms }
    end

    # @return   [Boolean]
    #   `true` if the list has a hierarchy, `false` otherwise.
    def hierarchical?
        @valid_platforms.is_a? Hash
    end

    def self.normalize( platforms )
        case platforms
            when self.class, Symbol
                platforms
            when String
                platforms.to_sym
            when Hash
                platforms.my_symbolize_keys
            when Enumerable, Array
                platforms.to_a.flatten.map( &:to_sym ).uniq.sort
        end
    end

    protected

    def platforms=( enum )
        @platforms = enum.to_a
    end

    private

    def find_children( platform, hash = @valid_platforms )
        return [] if hash.empty?

        children = []
        hash.each do |k, v|
            if k == platform
                children |= v.find_symbol_keys_recursively
            elsif v.is_a? Hash
                children |= find_children( platform, v )
            end

        end
        children
    end

    def find_parents( platform, hash = @valid_platforms )
        return [] if hash.empty?

        parents = []
        hash.each do |k, v|
            if v.include?( platform )
                parents << k
            elsif v.is_a? Hash
                parents |= find_parents( platform, v )
            end
        end
        parents
    end

    def normalize( platforms )
        return platforms if platforms.is_a? self.class

        if platforms.is_a?( Symbol ) || platforms.is_a?( String )
            platform = normalize!( platforms )
            if !valid.include?( platform )
                fail Error::Invalid, "Invalid platform: #{platform}"
            end

            return platform
        end

        platforms = normalize!( platforms )
        invalid   = (valid + platforms) - valid

        if invalid.any?
            fail Error::Invalid, "Invalid platforms: #{invalid.to_a.join( ', ' )}"
        end

        platforms
    end

    def normalize!( platforms )
        self.class.normalize( platforms )
    end

end

end
end
