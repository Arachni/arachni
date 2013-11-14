=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'list'
require_relative 'fingerprinter'

module Arachni

module Platform

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

#
# Represents a collection of platform {List lists}.
#
# It also holds a DB of all fingerprints per URI as a class variable and
# provides helper method for accessing and manipulating it.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Manager
    include Enumerable
    include Utilities
    extend  Utilities
    include UI::Output
    extend  UI::Output

    TYPES = {
        os:         'Operating systems',
        db:         'Databases',
        servers:    'Web servers',
        languages:  'Programming languages',
        frameworks: 'Frameworks'
    }

    OS = {
        # Generic *nix, flavor couldn't be identified.
        unix:    {
            linux:   {},

            # Generic BSD, flavor couldn't be identified.
            bsd:     {},
            solaris: {}
        },
        windows: {}
    }

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
        :firebird,
        :maxdb,
        :sybase,
        :frontbase,
        :ingres,
        :hsqldb,
        :access
    ]

    SERVERS = [
        :apache,
        :nginx,
        :tomcat,
        :iis,
        :jetty
    ]

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

    PLATFORM_NAMES = {
        # Operating systems
        unix:       'Generic Unix family',
        linux:      'Linux',
        bsd:        'Generic BSD family',
        solaris:    'Solaris',
        windows:    'MS Windows',

        # Databases
        mysql:      'MySQL',
        pgsql:      'Postgresql',
        mssql:      'MSSQL',
        oracle:     'Oracle',
        sqlite:     'SQLite',
        emc:        'EMC',
        db2:        'DB2',
        coldfusion: 'ColdFusion',
        interbase:  'InterBase',
        informix:   'Informix',
        firebird:   'Firebird',
        maxdb:      'SaP Max DB',
        sybase:     'Sybase',
        frontbase:  'Frontbase',
        ingres:     'IngresDB',
        hsqldb:     'HSQLDB',
        access:     'MS Access',

        # Web servers
        apache:     'Apache',
        nginx:      'Nginx',
        tomcat:     'TomCat',
        iis:        'IIS',
        jetty:      'Jetty',

        # Programming languages
        php:    'PHP',
        jsp:    'JSP',
        python: 'Python',
        ruby:   'Ruby',
        asp:    'ASP',
        aspx:   'ASP.NET',
        perl:   'Perl',

        # Web frameworks
        rack:   'Rack'
    }

    def self.find_type( platform )
        @find_type ||= {}

        if @find_type.empty?
            TYPES.keys.each do |type|

                platforms = const_get( type.to_s.upcase.to_sym )
                platforms = platforms.find_symbol_keys_recursively if platforms.is_a?( Hash )

                platforms.each do |p|
                    @find_type[p] = type
                end
            end
        end

        @find_type[platform]
    end

    def self.valid
        @valid ||= Set.new( PLATFORM_NAMES.keys )
    end

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
            Component::Manager.new( Options.dir['fingerprinters'],
                                    Platform::Fingerprinters )
    end
    fingerprinters.load_all

    # Runs all fingerprinters against the given `page`.
    #
    # @param    [Page]  page    Page to fingerprint.
    # @return   [Manager]   Updated `self`.
    def self.fingerprint( page )
        fingerprinters.available.each do |name|
            exception_jail( false ) do
                fingerprinters[name].new( page ).run
            end
        end
        page
    end

    #
    # Sets platform manager for the given `uri`.
    #
    # @param    [String, URI]   uri
    # @param    [Enumerable] platforms
    #
    # @return   [Manager]
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def self.[]=( uri, platforms )
        return new( platforms ) if !(key = make_key( uri ))
        @platforms[key] =
            platforms.is_a?( self ) ? platforms : new( platforms )
    end

    #
    # Updates the `platforms` for the given `uri`.
    #
    # @param    [String, URI]   uri
    # @param    [Manager] platforms
    #
    # @return   [Manager] Updated manager.
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def self.update( uri, platforms )
        self[uri].update platforms
    end

    # @param    [String, URI]   uri
    # @return   [Manager] Platform for the given `uri`
    def self.[]( uri )
        return new if !(key = make_key( uri ))
        @platforms[key] ||= new
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

    # @return   [Hash{Integer=>Array<Symbol>}]
    #   Light representation of the fingerprint DB with URL hashes as keys
    #   and arrays of symbols for platforms as values.
    def self.light
        all.inject({}) { |h, (k, v)| h[k] = v.to_a; h }
    end

    # @param    [Hash{Integer=>Array<Symbol>}]   light_platforms
    #   Return value of {.light}.
    # @return   [Manager]
    def self.update_light( light_platforms )
        light_platforms.each do |url, platforms|
            @platforms[url] ||= new( platforms )
        end
        self
    end

    # @param    [Array<String, Symbol>] platforms
    #   Platforms with which to initialize the lists.
    def initialize( platforms = [] )
        @platforms = {}
        TYPES.keys.each do |type|
            @platforms[type] =
                List.new( self.class.const_get( type.to_s.upcase.to_sym ) )
        end

        update [platforms | Options.platforms].flatten.compact
    end

    # @!method os
    #   @return [List] Platform list for operating systems.
    #   @see OS

    # @!method db
    #   @return [List] Platform list for databases.
    #   @see DB

    # @!method servers
    #   @return [List] Platform list for web servers.
    #   @see SERVERS

    # @!method languages
    #   @return [List] Platform list for languages.
    #   @see LANGUAGES

    # @!method frameworks
    #   @return [List] Platform list for frameworks.
    #   @see FRAMEWORKS

    [:os, :db, :servers, :languages, :frameworks].each do |type|
        define_method type do
            @platforms[type]
        end
    end

    # Converts a platform shortname to a full name.
    #
    # @param    [String, Symbol]   platform
    #   Platform shortname.
    #
    # @return   [String]    Full name.
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def fullname( platform )
        PLATFORM_NAMES[normalize( platform )]
    end

    # Selects appropriate data, depending on the applicable platforms,
    # from `data_per_platform`.
    #
    # @param    [Hash{<Symbol, String> => Object}]   data_per_platform
    #   Hash with platform names as keys and arbitrary data as values.
    #
    # @return   [Hash]
    #   `data_per_platform` with non-applicable entries (for non-empty platform
    #   lists) removed. Data for platforms whose list is empty will not be removed.
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def pick( data_per_platform )
        data_per_list = {}
        data_per_platform.each do |platform, value|
            list = find_list( platform )
            data_per_list[list]           ||= {}
            data_per_list[list][platform]   = value
        end

        picked = {}
        data_per_list.each do |list, data|
            # If a platform list is empty pass the given data without picking...
            if list.empty?
                picked.merge! data
                next
            end

            # ...otherwise enforce its platform restrictions.
            picked.merge! list.pick( data )
        end

        picked
    end

    # @return   [Set<Symbol>]   List of valid platforms.
    def valid
        self.class.valid
    end

    # @param    [Symbol, String]  platform Platform to check.
    # @return   [Boolean]
    #   `true` if platform is valid (i.e. in {#valid}), `false` otherwise.
    # @see #invalid?
    def valid?( platform )
        valid.include? platform
    end

    # @param    [Symbol, String]  platform Platform to check.
    # @return   [Boolean]
    #   `true` if platform is invalid (i.e. not in {#valid}), `false` otherwise.
    # @see #invalid?
    def invalid?( platform )
        !valid?( platform )
    end

    # @param    [Block] block   Block to be passed each platform.
    # @return   [Enumerator, Manager]
    #   `Enumerator` if no `block` is given, `self` otherwise.
    def each( &block )
        return enum_for( __method__ ) if !block_given?
        @platforms.map { |_, p| p.to_a }.flatten.each( &block )
        self
    end

    # @param    [Symbol, String]    platform    Platform to check.
    # @return   [Boolean]
    #   `true` if one of the lists contains the `platform`, `false` otherwise.
    # @raise    [Error::Invalid]  On {#invalid?} `platforms`.
    def include?( platform )
        find_list( platform ).include?( platform )
    end

    # @return   [Boolean]
    #   `true` if there are no applicable platforms, `false` otherwise.
    def empty?
        !@platforms.map { |_, p| p.empty? }.include?( false )
    end

    # @return   [Boolean]
    #   `true` if there are applicable platforms, `false` otherwise.
    def any?
        !empty?
    end

    # @param    [Enumerable] enum Enumerable object containing platforms.
    # @return   [Manager] Updated `self`.
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def update( enum )
        enum.each { |p| self << p }
        self
    end

    # @param    [Symbol, String]    platform
    #   Platform to add to the appropriate list.
    # @return   [Manager] `self`
    # @raise    [Error::Invalid]  On {#invalid?} platforms.
    def <<( platform )
        find_list( platform ) << platform
        self
    end

    # @param    [String, Symbol]    platform
    #   Platform whose type to find
    # @return   [Symbol]    Platform type.
    def find_type( platform )
        self.class.find_type( platform )
    end

    # @param    [String, Symbol]    platform Platform whose list to find.
    # @return   [List]    Platform list.
    def find_list( platform )
        @platforms[find_type( normalize( platform ) )]
    end

    private

    def normalize( platform )
        platform = List.normalize( platform )
        fail Error::Invalid, "Invalid platform: #{platform}" if invalid?( platform )
        platform
    end

    def self.make_key( uri )
        return if !(parsed = Arachni::URI( uri ))
        parsed.without_query.persistent_hash
    end

end
end
end
