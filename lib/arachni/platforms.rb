=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
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
class Platform
    include Enumerable
    include Utilities
    extend  Utilities
    include UI::Output
    extend  UI::Output

    # Namespace under which all platform fingerprinter components reside.
    module Fingerprinters

        #
        # Provides utility methods for fingerprinter components as well as
        # the {Page} object to be fingerprinted
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        # @abstract
        class Base
            include Utilities

            # @return   [Page]  Page to fingerprint.
            attr_reader :page

            def initialize( page )
                @page = page
            end

            # Executes the payload of the fingerpreter.
            # @abstract
            def run
            end

            # @param    [String]    string
            # @return   [Boolean]
            #   `true` if either {#server} or {#powered_by} include `string`,
            #   `false` otherwise.
            def server_or_powered_by_include?( string )
                server.include?( string ) || powered_by.include?( string )
            end

            # @return   [Arachni::URI]  Parsed URL of the {#page}.
            def uri
                uri_parse( page.url )
            end

            # @return   [Hash]  URI parameters with keys and values downcased.
            def parameters
                @parameters ||= page.query_vars.downcase
            end

            # @return   [Hash]  Cookies as headers with keys and values downcased.
            def cookies
                @cookies ||= page.cookies.
                    inject({}) { |h, c| h.merge! c.simple }.downcase
            end

            # @return   [Hash]  Response headers with keys and values downcased.
            def headers
                @headers ||= page.response_headers.downcase
            end

            # @return   [String. nil] Value of the `X-Powered-By` header.
            def powered_by
                headers['x-powered-by'].to_s
            end

            # @return   [String. nil] Value of the `Server` header.
            def server
                headers['server'].to_s
            end

            # @return   [String] Downcased file extension of the page.
            def extension
                @extension ||= uri_parse( page.url ).resource_extension.to_s.downcase
            end

            # @return   [Platform]
            #   Platform for the given page, should be updated by the
            #   fingerprinter accordingly.
            def platforms
                page.platforms
            end

        end

    end

    #
    # {Platform} error namespace.
    #
    # All {Platform} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    #
    class Error < Arachni::Error

        # Raised on {Platform#invalid?} platform names.
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
        :informix,
        :firebird
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
        :aspx,
        :perl
    ]

    # WebApp frameworks.
    FRAMEWORKS = [
        :rack
    ]

    # Sets global platforms fingerprints
    # @private
    def self.set( platforms )
        @platforms = platforms
    end

    # Clears global platforms DB.
    def self.clear
        @platforms.clear
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
    # @return   [Platform]   Updated `self`.
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
    # @return   [Platform] `platforms`
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def self.[]=( uri, platforms )
        @platforms[make_key( uri )] =
            platforms.is_a?( self ) ? platforms : new( platforms )
    end

    #
    # Updates the `platforms` for the given `uri`.
    #
    # @param    [String, URI]   uri
    # @param    [Platform] platforms
    #
    # @return   [Platform] Updated platforms.
    def self.update( uri, platforms )
        self[uri].merge! platforms
    end

    # @param    [String, URI]   uri
    # @return   [Platform] Platform for the given `uri`
    def self.[]( uri )
        @platforms[make_key( uri )] ||= Platform.new
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

    # @return   [Hash<Integer, Platform>]
    #   Platform per {URI#persistent_hash hashed URL}.
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
        @platforms = Set.new( normalize( platforms ) )
    end

    # @return   [Array<Symbol>] Supported platforms.
    def all
        @all ||= os_flat + DB + SERVERS + LANGUAGES + FRAMEWORKS
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
    # @param    [Hash{<Symbol, String> => Object}]   data_per_platform
    #   Hash with platform names as keys and arbitrary data as values.
    #
    # @return   [Hash]  `data_per_platform` with non-applicable entries removed.
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def pick( data_per_platform )
        orig_data_per_platform = data_per_platform.dup
        data_per_platform      = data_per_platform.dup

        data_per_platform.select! { |k, v| include? k }

        # Bail out if there are no operating systems included.
        return data_per_platform if (os_flat & orig_data_per_platform.keys).empty?

        # Keep track of parent OSs which will be removed due to the existence
        # of specific OS flavors for their type.
        specified_parents = []

        # Remove parent operating systems if we have specific flavors.
        data_per_platform.keys.each do |platform|
            specified_parents |= parents = find_parents( platform )
            data_per_platform.reject! { |k, _| parents.include? k }
        end

        # Include all of the parents' children if parents are specified but no
        # children for them.

        children = {}
        children_for = os_flat & @platforms.to_a
        children_for.each do |platform|
            next if specified_parents.include? platform
            c = find_children( platform )
            children.merge! orig_data_per_platform.select { |k, _| c.include? k }
        end

        data_per_platform.merge children
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
        @platforms.empty?
    end

    # @return   [Boolean]
    #   `true` if there are applicable platforms, `false` otherwise.
    def any?
        !empty?
    end

    # @param    [Symbol, String]    platform    Platform to add to the list.
    # @return   [Platform] `self`
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def <<( platform )
        @platforms << normalize( platform )
        self
    end

    # @param    [Platform, Enumerable] enum
    #   Enumerable object containing platforms.
    # @return   [Platform] Updated copy of `self`.
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def merge( enum )
        dup.merge!( enum )
    end

    # @param    [Enumerable] enum
    #   Enumerable object containing platforms.
    # @return   [Platform] Updated `self`.
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def merge!( enum )
        @platforms.merge normalize( enum )
        self
    end
    alias update merge!

    # @param    [Platform, Enumerable] enum
    #   {Platform} or enumerable object containing platforms.
    # @return   [Platform]
    #   New {Platform} built by merging `self` and the elements of the
    #   given enumerable object.
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def |( enum )
        dup.merge( enum )
    end
    alias + |

    # @param    [Block] block   Block to be passed each platform.
    # @return   [Enumerator, Platform]
    #   `Enumerator` if no block is given, `self` otherwise.
    def each( &block )
        return enum_for( __method__ ) if !block_given?
        @platforms.each( &block )
        self
    end

    # @param    [Symbol, String]    platform    Platform to check.
    # @return   [Boolean]
    #   `true` if `platform` applies to the given resource, `false` otherwise.
    # @raise    [Error::Invalid]  On {#invalid?} `platforms`.
    def include?( platform )
        @platforms.include? normalize( platform )
    end

    # @param    [Array<Symbol, String>]    platforms    Platform to check.
    # @return   [Boolean]
    #   `true` if any platform in `platforms` applies to the given resource,
    #   `false` otherwise.
    # @raise    [Error::Invalid]  On {#invalid?} `platforms`.
    def include_any?( platforms )
        (@platforms & normalize( platforms )).any?
    end

    # Clears platforms.
    def clear
        @platforms.clear
    end

    # @return   [Platform] Copy of `self`.
    def dup
        self.class.new( @platforms )
    end

    private

    def find_children( platform, hash = OS )
        return [] if hash.empty?

        children = []
        hash.each do |k, v|
            if k == platform
                children |= os_flat( v )
            elsif v.is_a? Hash
                children |= find_children( platform, v )
            end

        end
        children
    end

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
