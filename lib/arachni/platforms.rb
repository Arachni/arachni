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
    include Utilities
    extend  Utilities
    include UI::Output
    extend  UI::Output

    # Namespace under which all platform fingerprinter components reside.
    module Fingerprinters

        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        # @abstract
        class Base
            include Utilities

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
    OS = {
        # Generic *nix, flavor couldn't be identified.
        unix:    {
            linux:   {},

            # Generic BSD, flavor couldn't be identified.
            bsd:     {
                freebsd: {},
                openbsd: {},
            },
            solaris: {}
        },
        windows: {}
    }

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

    # Sets global platforms fingerprints
    # @private
    def self.set( platforms )
        @platforms = platforms
    end

    # Empties the global platform fingerprints.
    def self.reset
        set Hash.new
        @manager.clear if @manager
        @manager = nil
        self
    end
    reset

    def self.fingerprinters
        @manager ||=
            Component::Manager.new( Options.dir['fingerprinters'], Fingerprinters )
    end
    fingerprinters.load_all

    # Runs all fingerprinters against the given `page`.
    #
    # @param    [Page]  page    Page to fingerprint.
    # @return   [Platforms]   Updated `self`.
    def self.fingerprint( page )
        fingerprinters.available.each do |name|
            exception_jail( false ) do
                fingerprinters[name].new( page ).run
            end
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
        @platforms[make_key( uri )] =
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
        @platforms[make_key( uri )] ||= Platforms.new
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

    def self.make_key( uri )
        Arachni::URI( uri ).without_query.persistent_hash
    end

    # @param    [Array<String, Symbol>]    platforms
    #   List of platforms with which to initialize the instance.
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def initialize( platforms = [] )
        @applicable = Set.new( normalize( platforms ) )
    end

    # @return   [Array<Symbol>] Supported platforms.
    def all
        @all ||= os_flat + DB + SERVERS + LANGUAGES
    end

    # @return   [Array<Symbol>] Flat list of supported {OS operating systems}.
    def os_flat( hash = OS )
        flat = []
        hash.each do |k, v|
            flat << k
            flat |= os_flat( v ) if v.any?
        end
        flat.reject { |i| !i.is_a? Symbol }
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
        data_per_platform.select! { |k, v| include? k }

        # Bail out if there are no operating systems included.
        return data_per_platform if (os_flat & data_per_platform.keys).empty?

        # Remove parent operating systems if we have more specific identifiers.
        data_per_platform.keys.each do |platform|
            data_per_platform.reject! { |k, _| find_parents( platform ).include? k }
        end

        data_per_platform
    end

    # @param    [Array<Symbol, String> Symbol, String]  platforms
    #   Platform(s) to check.
    # @return   [Boolean]
    #   `true` if platforms are valid (i.e. in {#all}), `false` otherwise.
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
    #   `true` if platforms are invalid (i.e. not in {#all}), `false` otherwise.
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

    def find_parents( platform, hash = OS )
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
            platform = platforms.to_sym
            if !all.include?( platform )
                fail Error::Invalid, "Invalid platform: #{platform}"
            end

            return platform
        end

        platforms = platforms.map( &:to_sym ).uniq.sort
        invalid   = (all + platforms) - all

        if invalid.any?
            fail Error::Invalid, "Invalid platforms: #{invalid.join( ', ' )}"
        end

        platforms
    end

end

end
