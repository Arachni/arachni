=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

#
# Represents a collection of applicable platforms for a given remote resource.
#
# It also holds a DB of all fingerprints per URI as a class variable and
# provides helper method for accessing and manipulating it.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Platforms
    include Enumerable

    # Namespace under which all platform fingerprinter components reside.
    module Fingerprinters

        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        # @abstract
        class Base

            attr_reader :page

            def initialize( page )
                @page = page
            end

            # @abstract
            def run
            end

            def platforms
                page.platforms
            end

        end

    end

    #
    # {Platforms} error namespace.
    #
    # All {Platforms} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    #
    class Error < Arachni::Error

        # Raised on {Platforms#invalid?} platform names.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class Invalid < Error
        end
    end

    # Operating systems.
    OS = [
        :unix, # Generic *nix, flavor couldn't be identified.
        :linux,
        :bsd, # *BSD flavors.
        :solaris,
        :windows
    ]

    # Databases.
    DB = [
        :mysql,
        :pgsql,
        :mssql,
        :oracle,
        :sqlite,
        :emc,
        :db2,
        :coldfusion,
        :interbase,
        :informix
    ]

    # Web servers.
    SERVERS = [
        :apache,
        :nginx,
        :tomcat,
        :iis
    ]

    # Web languages.
    LANGUAGES = [
        :php,
        :jsp,
        :python,
        :ruby,
        :asp,
        :aspx
    ]

    # All platforms.
    ALL = OS + DB + SERVERS + LANGUAGES

    # Sets global platforms fingerprints
    # @private
    def self.set( platforms )
        @platforms = platforms
    end

    # Empties the global platform fingerprints.
    def self.reset
        set Hash.new
        self
    end
    reset

    # Runs all fingerprinters against the given `page`.
    #
    # @param    [Page]  page    Page to fingerprint.
    # @return   [Platforms]   Updated `self`.
    def self.fingerprint( page )
        fingerprinters.available.each do |name|
            #exception_jail do
            fingerprinters[name].new( page ).run
            #end
        end
        page
    end

    #
    # Sets `platforms` for the given `uri`.
    #
    # @param    [String, URI]   uri
    # @param    [Enumerable] platforms
    #
    # @return   [Platforms] `platforms`
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def self.[]=( uri, platforms )
        @platforms[Arachni::URI( uri ).persistent_hash] =
            platforms.is_a?( self ) ? platforms : new( platforms )
    end

    #
    # Updates the `platforms` for the given `uri`.
    #
    # @param    [String, URI]   uri
    # @param    [Platforms] platforms
    #
    # @return   [Platforms] Updated platforms.
    def self.update( uri, platforms )
        self[uri].merge! platforms
    end

    # @param    [String, URI]   uri
    # @return   [Platforms] Platforms for the given `uri`
    def self.[]( uri )
        @platforms[Arachni::URI( uri ).persistent_hash] ||= Platforms.new
    end

    # @return   [Boolean]
    #   `true` if there are no platforms fingerprints, `false` otherwise.
    def self.empty?
        @platforms.empty?
    end

    # @return   [Boolean]
    #   `true` if there are platforms fingerprints, `false` otherwise.
    def self.any?
        !empty?
    end

    # @return   [Hash<Integer, Platforms>]
    #   Platforms per {URI#persistent_hash hashed URL}.
    def self.all
        @platforms
    end

    # @param    [Array<String, Symbol>]    platforms
    #   List of platforms with which to initialize the instance.
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def initialize( platforms = [] )
        @applicable = Set.new( normalize( platforms ) )
    end

    # Selects appropriate data depending on the applicable platforms
    # from `data_per_platform`.
    #
    # @param    [Hash{<Symbol, Object> => Object}]   data_per_platform
    #   Hash with platform names as keys and arbitrary data as values.
    #
    # @return   [Hash]  `data_per_platform` with non-applicable entries removed.
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def pick_applicable( data_per_platform )
        data_per_platform.select { |k, v| include? k }
    end

    # @param    [Array<Symbol, String> Symbol, String]  platforms
    #   Platform(s) to check.
    # @return   [Boolean]
    #   `true` if platforms are valid (i.e. in {ALL}), `false` otherwise.
    # @see #invalud?
    def valid?( platforms )
        normalize( platforms )
        true
    rescue
        false
    end

    # @param    [Array<Symbol, String> Symbol, String]  platforms
    #   Platform(s) to check.
    # @return   [Boolean]
    #   `true` if platforms are invalid (i.e. not in {ALL}), `false` otherwise.
    # @see #valid?
    def invalid?( platforms )
        !valid?( platforms )
    end

    # @return   [Boolean]
    #   `true` if there are no applicable platforms, `false` otherwise.
    def empty?
        @applicable.empty?
    end

    # @return   [Boolean]
    #   `true` if there are applicable platforms, `false` otherwise.
    def any?
        !empty?
    end

    # @param    [Symbol, String]    platform    Platform to add to the list.
    # @return   [Platforms] `self`
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def <<( platform )
        @applicable << normalize( platform )
        self
    end

    # @param    [Platforms, Enumerable] enum
    #   Enumerable object containing platforms.
    # @return   [Platforms] Updated copy of `self`.
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def merge( enum )
        dup.merge!( enum )
    end

    # @param    [Enumerable] enum
    #   Enumerable object containing platforms.
    # @return   [Platforms] Updated `self`.
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def merge!( enum )
        @applicable.merge normalize( enum )
        self
    end

    # @param    [Platforms, Enumerable] enum
    #   {Platforms} or enumerable object containing platforms.
    # @return   [Platforms]
    #   New {Platforms} built by merging `self` and the elements of the
    #   given enumerable object.
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def |( enum )
        dup.merge( enum )
    end
    alias + |

    # @param    [Block] block   Block to be passed each platform.
    # @return   [Enumerator, Platforms]
    #   `Enumerator` if no block is given, `self` otherwise.
    def each( &block )
        return enum_for( __method__ ) if !block_given?
        @applicable.each( &block )
        self
    end

    # @param    [Symbol, String]    platform    Platform to check.
    # @return   [Boolean]
    #   `true` if `platform` applies to the given resource, `false` otherwise.
    # @raise    [Error::Invalid]  On {#invalid?} `platforms`.
    def include?( platform )
        @applicable.include? normalize( platform )
    end

    # @param    [Array<Symbol, String>]    platforms    Platforms to check.
    # @return   [Boolean]
    #   `true` if any platform in `platforms` applies to the given resource,
    #   `false` otherwise.
    # @raise    [Error::Invalid]  On {#invalid?} `platforms`.
    def include_any?( platforms )
        (@applicable & normalize( platforms )).any?
    end

    # @return   [Platforms] Copy of `self`.
    def dup
        self.class.new( @applicable )
    end

    private

    def normalize( platforms )
        return platforms if platforms.is_a? self.class

        if platforms.is_a?( Symbol ) || platforms.is_a?( String )
            platform = platforms.to_sym
            if !ALL.include?( platform )
                fail Error::Invalid, "Invalid platform: #{platform}"
            end

            return platform
        end

        platforms = platforms.map( &:to_sym ).uniq.sort
        invalid   = (ALL + platforms) - ALL

        if invalid.any?
            fail Error::Invalid, "Invalid platforms: #{invalid.join( ', ' )}"
        end

        platforms
    end

    def self.fingerprinters
        @manager ||=
            Component::Manager.new( Options.dir['fingerprinters'], Fingerprinters )
    end

end

end
