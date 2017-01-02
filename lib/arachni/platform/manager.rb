=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'list'
require_relative 'fingerprinter'

module Arachni
module Platform

# {Platform} error namespace.
#
# All {Platform} errors inherit from and live under it.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Error < Arachni::Error

    # Raised on {Manager#invalid?} platform names.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Invalid < Error
    end
end

# Represents a collection of platform {List lists}.
#
# It also holds a DB of all fingerprints per URI as a class variable and
# provides helper method for accessing and manipulating it.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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
            aix:     {},
            solaris: {}
        },
        windows: {}
    }

    DB = {
        sql: {
            mysql:      {},
            pgsql:      {},
            mssql:      {},
            oracle:     {},
            sqlite:     {},
            ingres:     {},
            emc:        {},
            db2:        {},
            interbase:  {},
            informix:   {},
            firebird:   {},
            maxdb:      {},
            sybase:     {},
            frontbase:  {},
            hsqldb:     {},
            access:     {},
        },
        nosql: {
            mongodb:    {}
        }
    }

    SERVERS = [
        :apache,
        :nginx,
        :tomcat,
        :iis,
        :jetty,
        :gunicorn
    ]

    LANGUAGES = [
        :php,
        :java,
        :python,
        :ruby,
        :asp,
        :aspx,
        :perl
    ]

    # WebApp frameworks.
    FRAMEWORKS = [
        :rack,
        :rails,
        :cakephp,
        :symfony,
        :nette,
        :django,
        :aspx_mvc,
        :jsf,
        :cherrypy
    ]

    PLATFORM_NAMES = {
        # Operating systems
        unix:       'Generic Unix family',
        linux:      'Linux',
        bsd:        'Generic BSD family',
        aix:        'IBM AIX',
        solaris:    'Solaris',
        windows:    'MS Windows',

        # Databases
        sql:        'Generic SQL family',
        mysql:      'MySQL',
        pgsql:      'Postgresql',
        mssql:      'MSSQL',
        oracle:     'Oracle',
        sqlite:     'SQLite',
        emc:        'EMC',
        db2:        'DB2',
        interbase:  'InterBase',
        informix:   'Informix',
        firebird:   'Firebird',
        maxdb:      'SaP Max DB',
        sybase:     'Sybase',
        frontbase:  'Frontbase',
        ingres:     'IngresDB',
        hsqldb:     'HSQLDB',
        access:     'MS Access',
        nosql:      'Generic NoSQL family',
        mongodb:    'MongoDB',

        # Web servers
        apache:     'Apache',
        nginx:      'Nginx',
        tomcat:     'TomCat',
        iis:        'IIS',
        jetty:      'Jetty',
        gunicorn:   'Gunicorn',

        # Programming languages
        php:    'PHP',
        java:   'Java',
        python: 'Python',
        ruby:   'Ruby',
        asp:    'ASP',
        aspx:   'ASP.NET',
        perl:   'Perl',

        # Web frameworks
        rack:     'Rack',
        django:   'Django',
        cakephp:  'CakePHP',
        nette:    'Nette',
        symfony:  'Symfony',
        rails:    'Ruby on Rails',
        aspx_mvc: 'ASP.NET MVC',
        jsf:      'JavaServer Faces',
        cherrypy: 'CherryPy'
    }

    PLATFORM_CACHE_SIZE = 500

    def self.synchronize( &block )
        @mutex.synchronize( &block )
    end

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

    def self.valid?( platforms )
        platforms = [platforms].flatten.compact
        (valid & platforms).to_a == platforms
    end

    # Sets global platforms fingerprints
    # @private
    def self.set( platforms )
        @platforms = Support::Cache::LeastRecentlyPushed.new( PLATFORM_CACHE_SIZE )
        platforms.each { |k, v| @platforms[k] = v }
        @platforms
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

        @mutex  = Monitor.new

        self
    end
    reset

    def self.fingerprinters
        @manager ||=
            Component::Manager.new( Options.paths.fingerprinters,
                                    Platform::Fingerprinters )
    end
    fingerprinters.load_all

    # @param    [HTTP::Response, Page]  resource
    #
    # @return   [Bool]
    #   `true` if the resource should be fingerprinted, `false` otherwise.
    def self.fingerprint?( resource )
        !(!Options.fingerprint? || resource.code != 200 || !resource.text? ||
            include?( resource.url ) || resource.scope.out?)
    end

    # Runs all fingerprinters against the given `page`.
    #
    # @param    [Page]  page
    #   Page to fingerprint.
    #
    # @return   [Manager]
    #   Updated `self`.
    def self.fingerprint( page )
        synchronize do
            return page if !fingerprint? page

            fingerprinters.available.each do |name|
                exception_jail( false ) do
                    fingerprinters[name].new( page ).run
                end
            end

            # We do this to flag the resource as checked even if no platforms
            # were identified. We don't want to keep checking a resource that
            # yields nothing over and over.
            update( page.url, [] )
        end

        # Fingerprinting will have resulted in element parsing, clear the element
        # caches to keep RAM consumption down.
        page.clear_cache
    end

    # @param    [String, URI]   uri
    #
    # @return   [Manager]
    #   Platform for the given `uri`
    def self.[]( uri )
        # If fingerprinting is disabled there's no point in filling the cache
        # with the same object over and over, create an identical one for all
        # URLs and return that always.
        if !Options.fingerprint?
            return @default ||= new_from_options
        end

        return new_from_options if !(key = make_key( uri ))
        synchronize { @platforms.fetch(key) { new_from_options } }
    end

    # Sets platform manager for the given `uri`.
    #
    # @param    [String, URI]   uri
    # @param    [Enumerable] platforms
    #
    # @return   [Manager]
    #
    # @raise    [Error::Invalid]
    #   On {#invalid?} platforms.
    def self.[]=( uri, platforms )
        # For some reason we failed to make a key, try to salvage the situation.
        if !(key = make_key( uri ))
            return new_from_options( platforms )
        end

        synchronize do
            @platforms[key] =
                platforms.is_a?( self ) ?
                    platforms :
                    new_from_options( platforms )
        end
    end

    def self.size
        @platforms.size
    end

    # @param    [String, URI]   uri
    def self.include?( uri )
        @platforms.include?( make_key( uri ) )
    end

    # Updates the `platforms` for the given `uri`.
    #
    # @param    [String, URI]   uri
    # @param    [Manager] platforms
    #
    # @return   [Manager]
    #   Updated manager.
    #
    # @raise    [Error::Invalid]
    #   On {#invalid?} platforms.
    def self.update( uri, platforms )
        synchronize do
            self[uri].update platforms
        end
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

    def self.make_key( uri )
        return if !(parsed = Arachni::URI( uri ))
        parsed.without_query
    end

    def self.new_from_options( platforms = [] )
        new( platforms | Options.platforms )
    end

    # @param    [Array<String, Symbol>] platforms
    #   Platforms with which to initialize the lists.
    def initialize( platforms = [] )
        @platforms = {}
        TYPES.keys.each do |type|
            @platforms[type] =
                List.new( self.class.const_get( type.to_s.upcase.to_sym ) )
        end

        update platforms
    end

    # @!method os
    #   @return [List]
    #       Platform list for operating systems.
    #
    #   @see OS

    # @!method db
    #   @return [List]
    #       Platform list for databases.
    #
    #   @see DB

    # @!method servers
    #   @return [List]
    #       Platform list for web servers.
    #
    #   @see SERVERS

    # @!method languages
    #   @return [List]
    #       Platform list for languages.
    #
    #   @see LANGUAGES

    # @!method frameworks
    #   @return [List]
    #       Platform list for frameworks.
    #
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
    # @return   [String]
    #   Full name.
    #
    # @raise    [Error::Invalid]
    #   On {#invalid?} platforms.
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
    #
    # @raise    [Error::Invalid]
    #   On {#invalid?} platforms.
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

    # @return   [Set<Symbol>]
    #   List of valid platforms.
    def valid
        self.class.valid
    end

    # @param    [Symbol, String]  platform
    #   Platform to check.
    #
    # @return   [Boolean]
    #   `true` if platform is valid (i.e. in {#valid}), `false` otherwise.
    #
    # @see #invalid?
    def valid?( platform )
        valid.include? platform
    end

    # @param    [Symbol, String]  platform
    #   Platform to check.
    #
    # @return   [Boolean]
    #   `true` if platform is invalid (i.e. not in {#valid}), `false` otherwise.
    #
    # @see #invalid?
    def invalid?( platform )
        !valid?( platform )
    end

    # @param    [Block] block
    #   Block to be passed each platform.
    #
    # @return   [Enumerator, Manager]
    #   `Enumerator` if no `block` is given, `self` otherwise.
    def each( &block )
        return enum_for( __method__ ) if !block_given?
        @platforms.map { |_, p| p.to_a }.flatten.each( &block )
        self
    end

    # @param    [Symbol, String]    platform
    #   Platform to check.
    #
    # @return   [Boolean]
    #   `true` if one of the lists contains the `platform`, `false` otherwise.
    #
    # @raise    [Error::Invalid]
    #   On {#invalid?} `platforms`.
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

    def clear
        @platforms.clear
    end

    # @param    [Enumerable] enum
    #   Enumerable object containing platforms.
    #
    # @return   [Manager]
    #   Updated `self`.
    #
    # @raise    [Error::Invalid]
    #   On {#invalid?} platforms.
    def update( enum )
        enum.each { |p| self << p }
        self
    end

    # @param    [Symbol, String]    platform
    #   Platform to add to the appropriate list.
    #
    # @return   [Manager]
    #   `self`
    #
    # @raise    [Error::Invalid]
    #   On {#invalid?} platforms.
    def <<( platform )
        find_list( platform ) << platform
        self
    end

    # @param    [String, Symbol]    platform
    #   Platform whose type to find
    #
    # @return   [Symbol]    Platform type.
    def find_type( platform )
        self.class.find_type( platform )
    end

    # @param    [String, Symbol]    platform
    #   Platform whose list to find.
    #
    # @return   [List]
    #   Platform list.
    def find_list( platform )
        @platforms[find_type( normalize( platform ) )]
    end

    private

    def normalize( platform )
        platform = List.normalize( platform )
        fail Error::Invalid, "Invalid platform: #{platform}" if invalid?( platform )
        platform
    end

end
end
end
