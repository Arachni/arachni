=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'yaml'
require 'singleton'

require_relative 'error'
require_relative 'utilities'

module Arachni

# Provides access to all of {Arachni}'s runtime options.
#
# To make management of options for different subsystems easier, some options
# are {OptionGroups grouped together}.
#
# {OptionGroups Option groups} are initialized and added as attribute readers
# to this class dynamically. Their attribute readers are named after the group's
# filename and can be accessed, like so:
#
#     Arachni::Options.scope.page_limit = 10
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @see OptionGroups
class Options
    include Singleton

    # {Options} error namespace.
    #
    # All {Options} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Arachni::Error

        # Raised when a provided {Options#url= URL} is invalid.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class InvalidURL < Error
        end

        # Raised when a provided 'localhost' or '127.0.0.1' {Options#url= URL}.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class ReservedHostname < Error
        end
    end

    class <<self

        def method_missing( sym, *args, &block )
            if instance.respond_to?( sym )
                instance.send( sym, *args, &block )
            else
                super( sym, *args, &block )
            end
        end

        def respond_to?( *args )
            super || instance.respond_to?( *args )
        end

        # Ruby 2.0 doesn't like my class-level method_missing for some reason.
        # @private
        public :allocate

        # @return   [Hash<Symbol,OptionGroup>]
        #   {OptionGroups Option group} classes by name.
        def group_classes
            @group_classes ||= {}
        end

        # Should be called by {OptionGroup.inherited}.
        # @private
        def register_group( group )
            name = Utilities.caller_name

            # Prepare an attribute reader for this group...
            attr_reader name

            # ... and initialize it.
            instance_variable_set "@#{name}".to_sym, group.new

            group_classes[name.to_sym] = group
        end
    end

    # Load all {OptionGroups}.
    require_relative 'option_groups'

    # @return    [String]
    #   The URL to audit.
    attr_reader   :url

    # @return    [Arachni::URI]
    attr_reader   :parsed_url

    # @return    [Array<String, Symbol>]
    #   Checks to load, by name.
    #
    # @see Checks
    # @see Check::Base
    # @see Check::Manager
    attr_accessor :checks

    # @return   [Array<Symbol>]
    #   Platforms to use instead of (or in addition to, depending on the
    #   {#no_fingerprinting option}) fingerprinting.
    #
    # @see Platform
    # @see Platform::List
    # @see Platform::Manager
    attr_accessor :platforms

    # @return   [Hash{<String, Symbol> => Hash{String => String}}]
    #   Plugins to load, by name, as keys and their options as values.
    #
    # @see Plugins
    # @see Plugin::Base
    # @see Plugin::Manager
    attr_accessor :plugins

    # @return    [String]
    #   E-mail address of the person that authorized the scan. It will be added
    #   to the HTTP `From` headers.
    #
    # @see HTTP::Client#headers
    attr_accessor :authorized_by

    # @return   [Bool]
    #   Disable platform fingeprinting.
    #
    # @see Platform::Fingerprinter
    # @see Platform::Fingerprinters
    # @see Platform::List
    # @see Platform::Manager
    attr_accessor :no_fingerprinting

    # @return   [Integer]
    #   Amount of child {RPC::Server::Instance}s to spawn when performing
    #   multi-{RPC::Server::Instance} scans.
    #
    # @see UI::CLI::RPC::Instance#scan
    attr_accessor :spawns

    def initialize
        reset
    end

    # Restores everything to their default values.
    #
    # @return [Options] `self`
    def reset
        # nil everything out.
        instance_variables.each { |var| instance_variable_set( var.to_s, nil ) }

        # Set fresh option groups.
        group_classes.each do |name, klass|
            instance_variable_set "@#{name}".to_sym, klass.new
        end

        @checks    = []
        @platforms = []
        @plugins   = {}
        @spawns    = 0

        @no_fingerprinting = false
        @authorized_by     = nil

        self
    end

    # @param    [Integer]   spawns
    #
    # @see #spawns
    def spawns=( spawns )
        @spawns = spawns.to_i
    end

    # Disables platform fingerprinting.
    def do_not_fingerprint
        self.no_fingerprinting = true
    end

    # Enables platform fingerprinting.
    def fingerprint
        self.no_fingerprinting = false
    end

    # @return   [Bool]
    #   `true` if platform fingerprinting is enabled, `false` otherwise.
    def fingerprint?
        !@no_fingerprinting
    end

    # Normalizes and sets `url` as the target URL.
    #
    # @param    [String]    url
    #   Absolute URL of the targeted web app.
    #
    # @return   [String]
    #   Normalized `url`
    #
    # @raise    [Error::InvalidURL]
    #   If the given `url` is not valid.
    def url=( url )
        return @url = nil if !url

        parsed = Arachni::URI( url.to_s )

        if parsed.to_s.empty? || !parsed.absolute?

            fail Error::InvalidURL,
                 'Invalid URL argument, please provide a full absolute URL and try again.'

        # PhantomJS won't proxy localhost.
        elsif parsed.host == 'localhost' || parsed.host.start_with?( '127.' )

            fail Error::ReservedHostname,
                 "Loopback interfaces (like #{parsed.host}) are not supported," <<
                     ' please use a different IP address or hostname.'

        else

            if scope.https_only? && parsed.scheme != 'https'

                fail Error::InvalidURL,
                     "Invalid URL argument, the 'https-only' option requires"+
                         ' an HTTPS URL.'

            elsif !%w(http https).include?( parsed.scheme )

                fail Error::InvalidURL,
                     'Invalid URL scheme, please provide an HTTP or HTTPS URL and try again.'

            end

        end

        @parsed_url = parsed
        @url        = parsed.to_s
    end

    # Configures options via a Hash object.
    #
    # @example Configuring direct and {OptionGroups} attributes.
    #
    #     {
    #         # Direct Options#url attribute.
    #         url:    'http://test.com/',
    #         # Options#audit attribute pointing to an OptionGroups::Audit instance.
    #         audit:  {
    #             # Works due to the OptionGroups::Audit#elements= helper method.
    #             elements: [ :links, :forms, :cookies ]
    #         },
    #         # Direct Options#checks attribute.
    #         checks: [ :xss, 'sql_injection*' ],
    #         # Options#scope attribute pointing to an OptionGroups::Scope instance.
    #         scope:  {
    #             # OptionGroups::Scope#page_limit
    #             page_limit:            10,
    #             # OptionGroups::Scope#directory_depth_limit
    #             directory_depth_limit: 3
    #         },
    #         # Options#http attribute pointing to an OptionGroups::HTTP instance.
    #         http:  {
    #             # OptionGroups::HTTP#request_concurrency
    #             request_concurrency: 25,
    #             # OptionGroups::HTTP#request_timeout
    #             request_timeout:     10_000
    #         }
    #     }
    #
    # @param    [Hash]  options
    #   If the key refers to a class attribute, the attribute will be assigned
    #   the given value, if it refers to one of the {OptionGroups} the value
    #   should be a hash with data to update that {OptionGroup group} using
    #   {OptionGroup#update}.
    #
    # @return   [Options]
    #
    # @see OptionGroups
    def update( options )
        options.each do |k, v|
            k = k.to_sym
            if group_classes.include? k
                send( k ).update v
            else
                send( "#{k.to_s}=", v )
            end
        end

        self
    end
    alias :set :update

    # @return   [Hash]
    #   Hash of errors with the name of the invalid options/groups as the keys.
    def validate
        errors = {}
        group_classes.keys.each do |name|
            next if (group_errors = send(name).validate).empty?
            errors[name] = group_errors
        end
        errors
    end

    # @param    [String]    file
    #   Saves `self` to `file` using YAML.
    def save( file )
        File.open( file, 'w' ) do |f|
            f.write to_save_data
            f.path
        end
    end

    def to_save_data
        to_rpc_data.to_yaml
    end

    # Loads a file created by {#save}.
    #
    # @param    [String]    filepath
    #   Path to the file created by {#save}.
    #
    # @return   [Arachni::Options]
    def load( filepath )
        update( YAML.load_file( filepath ) )
    end

    # @return    [Hash]
    #   `self` converted to a Hash suitable for RPC transmission.
    def to_rpc_data
        ignore = Set.new([:instance, :rpc, :dispatcher, :paths, :spawns,
                          :snapshot, :output])

        hash = {}
        instance_variables.each do |var|
            val = instance_variable_get( var )
            var = normalize_name( var )

            next if ignore.include?( var )

            hash[var.to_s] = (val.is_a? OptionGroup) ? val.to_rpc_data : val
        end
        hash = hash.deep_clone

        hash.delete( 'url' ) if !hash['url']
        hash.delete( 'parsed_url' )

        hash
    end

    # @return    [Hash]
    #   `self` converted to a Hash.
    def to_hash
        hash = {}
        instance_variables.each do |var|
            val = instance_variable_get( var )
            next if (var = normalize_name( var )) == :instance

            hash[var] = (val.is_a? OptionGroup) ? val.to_h : val
        end

        hash.delete( :url ) if !hash[:url]
        hash.delete( :parsed_url )
        hash.delete(:paths)

        hash.deep_clone
    end
    alias :to_h :to_hash

    # @param    [Hash]  hash
    #   Hash to convert into {#to_hash} format.
    #
    # @return   [Hash]
    #   `hash` in {#to_hash} format.
    def rpc_data_to_hash( hash )
        self.class.allocate.reset.update( hash ).to_hash
    end

    # @param    [Hash]  hash
    #   Hash to convert into {#to_rpc_data} format.
    #
    # @return   [Hash]
    #   `hash` in {#to_rpc_data} format.
    def hash_to_rpc_data( hash )
        self.class.allocate.reset.update( hash ).to_rpc_data
    end

    def hash_to_save_data( hash )
        self.class.allocate.reset.update( hash ).to_save_data
    end

    private

    def group_classes
        self.class.group_classes
    end

    def normalize_name( name )
        name.to_s.gsub( '@', '' ).to_sym
    end

end
end
