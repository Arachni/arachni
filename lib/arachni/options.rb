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

require 'rubygems'
require 'bundler/setup'

require 'base64'

require 'yaml'

require 'singleton'
require 'getoptlong'

require_relative 'error'

module Arachni

#
# Options storage class.
#
# Implements the Singleton pattern and formally defines all of Arachni's runtime options.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Options
    include Singleton

    #
    # {Options} error namespace.
    #
    # All {Options} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    #
    class Error < Arachni::Error

        #
        # Raised when a provided {Options#url= URL} is invalid.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        #
        class InvalidURL < Error
        end
    end

    #
    # The extension of the profile files.
    #
    # @return    [String]
    #
    PROFILE_EXT = '.afp'

    USER_AGENT = 'Arachni/v' + Arachni::VERSION.to_s

    #
    # General purpose datastore.
    #
    # Since this class is a Singleton and is passed
    # to pretty much everything it's a good candidate for message passing
    # or obscure options that the user doesn't need to know.
    #
    # @return    [Hash]
    #
    attr_reader   :datastore

    # @return [Integer] maximum retries for failed RPC calls
    attr_accessor :max_retries

    #
    # @return   [String]    the URL of a neighbouring Dispatcher
    #
    attr_accessor :neighbour

    #
    # @return   [Float]    how soon to check for neighbour node status
    #
    attr_accessor :node_ping_interval

    #
    # @return   [Float]    cost of using the Dispatcher
    #
    attr_accessor :cost

    #
    # @return   [String]    a string identifying this bandwidth pipe
    #
    attr_accessor :pipe_id

    #
    # @return   [Float]    Dispatcher weight
    #
    attr_accessor :weight

    #
    # @return   [String]    Dispatcher nickname
    #
    attr_accessor :nickname

    #
    # Holds absolute paths for the directory structure of the framework
    #
    # @return    [Hash]
    #
    attr_accessor :dir

    #
    # The URL to audit
    #
    # @return    [String]
    #
    attr_reader   :url

    #
    # Show help?
    #
    # @return    [Bool]
    #
    attr_accessor :help

    #
    # Output only positive results during the audit?
    #
    # @return    [Bool]
    #
    attr_accessor :only_positives

    #
    # Be verbose?
    #
    # @return    [Bool]
    #
    attr_accessor :arachni_verbose

    #
    # Output debugging messages?
    #
    # @return    [Bool]
    #
    attr_accessor :debug

    #
    # Filters for redundant links in the form of (pattern => counter).
    #
    # @return    [Hash[Regexp, Integer]]
    #
    attr_accessor :redundant

    #
    # Should the crawler obery robots.txt files?
    #
    # @return    [Bool]
    #
    attr_accessor :obey_robots_txt

    # @note `nil` is infinite -- default is `nil`.
    #
    # How deep to go in the site structure?
    #
    # @return    [Integer]
    #
    attr_accessor :depth_limit

    # @note `nil` is infinite -- default is `10`.
    #
    # How deep to go into each page's DOM tree.
    #
    # @return    [Integer]
    attr_accessor :dom_depth_limit

    #
    # How many links to follow?
    # If -1, link_count_limit = inf
    #
    # @return    [Integer]
    #
    attr_accessor :link_count_limit

    #
    # How many redirects to follow?
    # If -1, redirect_limit = inf
    #
    # @return    [Integer]
    #
    attr_accessor :redirect_limit

    #
    # List modules, based on regexps, and exit?
    #
    # @return    [Array<Regexp>]
    #
    attr_accessor :lsmod

    #
    # List reports and exit?
    #
    # @return    [Bool]
    #
    attr_accessor :lsrep

    #
    # How many concurrent HTTP requests?
    #
    # @return    [Integer]
    #
    attr_accessor :http_req_limit

    #
    # Should Arachni audit links?
    #
    # @return    [Bool]
    #
    attr_accessor :audit_links

    #
    # Should Arachni audit forms?
    #
    # @return    [Bool]
    #
    attr_accessor :audit_forms

    #
    # Should Arachni audit cookies?
    #
    # @return    [Bool]
    #
    attr_accessor :audit_cookies

    attr_accessor :audit_cookies_extensively
    alias :audit_cookies_extensively? :audit_cookies_extensively

    #
    # Should Arachni audit HTTP headers?
    #
    # @return    [Bool]
    #
    attr_accessor :audit_headers

    #
    # Array of modules to load
    #
    # @return    [Array]
    #
    attr_accessor :mods

    #
    # Array of reports to load
    #
    # @return    [Array]
    #
    attr_accessor :reports

    #
    # Location of an Arachni Framework Report (.afr) file to load
    #
    # @return    [String]
    #
    attr_accessor :repload

    #
    # Where to save the Arachni Framework Profile (.afp) file
    #
    # @return    [String]
    #
    attr_accessor :save_profile

    #
    # Location of Arachni Framework Profile (.afp) files to load
    #
    # @return    [Array]
    #
    attr_accessor :load_profile


    attr_accessor :show_profile

    #
    # The person that authorized the scan<br/>
    # It will be added to the HTTP "user-agent" and "from" headers.
    #
    # @return    [String]
    #
    attr_accessor :authed_by

    #
    # The address of the proxy server
    #
    # @return    [String]
    #
    attr_accessor :proxy_host

    #
    # The port to connect on the proxy server
    #
    # @return    [String]
    #
    attr_accessor :proxy_port

    #
    # The proxy password
    #
    # @return    [String]
    #
    attr_accessor :proxy_password

    #
    # The proxy user
    #
    # @return    [String]
    #
    attr_accessor :proxy_username

    #
    # The proxy type
    #
    # @return    [String]     [http, socks]
    #
    attr_accessor :proxy_type

    # @return    [String]     Proxy URL (`host:port`)
    attr_accessor :proxy

    #
    # To be populated by the framework
    #
    # Parsed cookiejar cookies
    #
    # @return    [Hash]     name=>value pairs
    #
    attr_accessor :cookies

    #
    # Location of the cookiejar
    #
    # @return    [String]
    #
    attr_accessor :cookie_jar

    #
    # @return    [String]   cookies in the form of "name=value; name2=value2"
    #
    attr_accessor :cookie_string

    #
    # The HTTP user-agent to use
    #
    # @return    [String]
    #
    attr_accessor :user_agent

    #
    # Exclusion filters.
    #
    # URLs matching any of these patterns won't be followed or audited.
    #
    # @return    [Array]
    #
    attr_accessor :exclude

    #
    # Page bodies matching any of these patterns will be are ignored.
    #
    # @return    [Array]
    #
    attr_accessor :exclude_pages

    #
    # Cookies to exclude from the audit
    #
    # @return    [Array]
    #
    attr_accessor :exclude_cookies

    #
    # Vectors to exclude from the audit
    #
    # @return    [Array]
    #
    attr_accessor :exclude_vectors

    #
    # Inclusion filters.
    #
    # Only URLs that match any of these patterns will be followed.
    #
    # @return    [Array]
    #
    attr_accessor :include

    #
    # Should the crawler follow subdomains?
    #
    # @return    [Bool]
    #
    attr_accessor :follow_subdomains

    # @return   [Time]  to be populated by the framework
    attr_accessor :start_datetime

    # @return   [Time]   to be populated by the framework
    attr_accessor :finish_datetime

    # @return   [Integer]   to be populated by the framework
    attr_accessor :delta_time

    # @return   [Array<Regexp>] regexps to use to select which plugins to list
    attr_accessor :lsplug

    # @return   [Array<String>] plugins to load, by name
    attr_accessor :plugins

    # @return   [String]   Path to the UNIX socket to use.
    attr_accessor :rpc_socket

    # @return   [Integer]   port for the RPC server to listen to
    attr_accessor :rpc_port

    # @return   [String]   (hostname or IP) address for the RPC server to bind to
    attr_accessor :rpc_address

    # @return   [Array<Integer>]
    #   Range of ports to use when spawning instances,
    #   first element should be the lowest port number, last the max port number.
    attr_accessor :rpc_instance_port_range

    # @return   [Bool]  `true` if SSL should be enabled, `false` otherwise.
    attr_accessor :ssl

    # @return   [String]  path to a PEM private key
    attr_accessor :ssl_pkey

    # @return   [String]  path to a PEM certificate
    attr_accessor :ssl_cert

    # @return   [String]  path to a PEM CA file
    attr_accessor :ssl_ca

    # @return   [String]  path to a client PEM private key for the grid nodes
    attr_accessor :node_ssl_pkey

    # @return   [String]  path to a client PEM certificate key for the grid nodes
    attr_accessor :node_ssl_cert

    # @return   [String]  URL of an RPC dispatcher (used by the CLI RPC client interface)
    attr_accessor :server

    # @return   [Bool]  `true` if the output of the RPC instances should be
    #                       redirected to a file, `false` otherwise
    attr_accessor :reroute_to_logfile

    # @return   [Integer]   amount of Instances to keep in the pool
    attr_accessor :pool_size

    # @return   [Hash<String, String>]    custom HTTP headers to be included
    #                                           for every HTTP Request
    attr_accessor :custom_headers

    # @return   [Array<String>] paths to use instead of crawling the webapp
    attr_accessor :restrict_paths

    # @return   [String] path to file containing {#restrict_paths}
    attr_accessor :restrict_paths_filepath

    # @return   [Array<String>] paths to use in addition to crawling the webapp
    attr_accessor :extend_paths

    # @return   [String] path to file containing {#extend_paths}
    attr_accessor :extend_paths_filepath

    # @return   [Integer]   minimum pages per RPC Instance when in High Performance Mode
    attr_accessor :min_pages_per_instance

    # @return   [Integer]   maximum amount of slave Instances to use
    attr_accessor :max_slaves

    # @return   [Integer]   amount of child Instances to spawn
    attr_accessor :spawns

    attr_accessor :fuzz_methods

    attr_accessor :exclude_binaries

    # @return   [Bool]   configure the {Spider}'s auto-redundant feature
    attr_accessor :auto_redundant

    attr_accessor :login_check_url
    attr_accessor :login_check_pattern

    # @return   [Integer]   HTTP request timeout in milliseconds
    attr_accessor :http_timeout

    # @return   [Integer]   HTTP auth username.
    attr_accessor :http_username

    # @return   [Integer]   HTTP auth password.
    attr_accessor :http_password

    # @return   [Bool]   Only follow HTTPS links.
    attr_accessor :https_only

    # @return   [nil, Symbol]
    #   Grid mode to use, available modes are:
    #
    #   * `nil` -- No grid.
    #   * `:balance` -- Default load balancing across available Dispatchers.
    #   * `:aggregate` -- Default load balancing **with** line aggregation.
    #       Will only request Instances from Grid members with different
    #       {#pipe_id Pipe-IDs}.
    attr_accessor :grid_mode

    # @return   [Bool]   Disable platform fingeprinting.
    attr_accessor :no_fingerprinting

    # @return   [Array<Symbol>]
    #   User supplied platforms to use instead of (or in addition to --
    #   depending on the {#no_fingerprinting option}) fingerprinting.
    attr_accessor :platforms

    attr_accessor :lsplat

    # @return   [Bool]   Display version info and quit?
    attr_accessor :version

    def initialize
        reset
    end

    def reset
        # nil everything out
        self.instance_variables.each { |var| instance_variable_set( var.to_s, nil ) }

        @dir            = {}
        @dir['root']    = root_path
        @dir['gfx']     = @dir['root'] + 'gfx/'
        @dir['conf']    = @dir['root'] + 'conf/'

        @dir['logs']    = ENV['ARACHNI_FRAMEWORK_LOGDIR'] ?
            "#{ENV['ARACHNI_FRAMEWORK_LOGDIR']}/" : @dir['root'] + 'logs/'

        @dir['data']    = @dir['root'] + 'data/'
        @dir['modules'] = @dir['root'] + 'modules/'
        @dir['reports'] = @dir['root'] + 'reports/'
        @dir['plugins'] = @dir['root'] + 'plugins/'
        @dir['rpcd_handlers']   = @dir['root'] + 'rpcd_handlers/'
        @dir['path_extractors'] = @dir['root'] + 'path_extractors/'
        @dir['fingerprinters']  = @dir['root'] + 'fingerprinters/'

        @dir['lib']     = @dir['root'] + 'lib/arachni/'
        @dir['support'] = @dir['lib'] + 'support/'
        @dir['mixins']  = @dir['lib'] + 'mixins/'
        @dir['arachni'] = @dir['lib'][0...-1]

        # we must add default values for everything because that can serve
        # both as a default configuration and as an inexpensive way to declare
        # their data types for later verification

        @user_agent   = USER_AGENT
        @http_timeout = 50000

        @datastore  = {}
        @redundant  = {}

        @grid_mode = nil

        @https_only        = false
        @obey_robots_txt   = false
        @fuzz_methods      = false
        @audit_cookies_extensively = false
        @exclude_binaries  = false
        @auto_redundant    = nil

        @depth_limit      = nil
        @dom_depth_limit  = 10
        @link_count_limit = nil
        @redirect_limit   = 20

        @lsmod  = []
        @lsrep  = []

        @http_req_limit = 20
        @http_username = nil
        @http_password = nil

        @mods = []

        @reports    = {}

        @exclude    = []
        @exclude_pages   = []
        @exclude_cookies = []
        @exclude_vectors = []

        @include    = []

        @lsplug     = []
        @plugins    = {}

        @rpc_instance_port_range = [1025, 65535]

        @load_profile       = []
        @restrict_paths     = []
        @extend_paths       = []
        @custom_headers     = {}

        @min_pages_per_instance = 30
        @max_slaves = 10

        @no_fingerprinting = false
        @platforms = []

        @spawns = 0
        self
    end

    # @return   [Bool]  `true` if the Grid should be used, `false` otherwise.
    def grid?
        !!@grid_mode
    end

    # @param    [Bool]  bool
    #   `true` to use the Grid, `false` otherwise. Serves as a shorthand to
    #   setting {#grid_mode} to `:balance`.
    def grid=( bool )
        @grid_mode = bool ? :balance : nil
    end

    # @param    [String, Symbol]    mode
    #   Grid mode to use, available modes are:
    #
    #   * `nil` -- No grid.
    #   * `:balance` -- Default load balancing across available Dispatchers.
    #   * `:aggregate` -- Default load balancing **with** line aggregation.
    #       Will only request Instances from Grid members with different
    #       {#pipe_id Pipe-IDs}.
    #
    # @raise    ArgumentError   On invalid mode.
    def grid_mode=( mode )
        if mode
            mode = mode.to_sym
            if ![:balance, :aggregate].include?( mode )
                fail ArgumentError, "Unknown grid mode: #{mode}"
            end

            @grid_mode = mode
        else
            @grid_mode = nil
        end
    end

    # @return   [Bool]
    #   `true` if the grid mode is in line-aggregation mode, `false` otherwise.
    def grid_aggregate?
        @grid_mode == :aggregate
    end

    # @return   [Bool]
    #   `true` if the grid mode is in load-balancing mode, `false` otherwise.
    def grid_balance?
        @grid_mode == :balance
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

    def show_version?
        !!@version
    end

    def https_only?
        !!@https_only
    end

    def min_pages_per_instance=( page_count )
        @min_pages_per_instance = page_count.to_i
    end

    def max_slaves=( slave_count )
        @max_slaves = slave_count.to_i
    end

    #
    # Checks is the provided URL matches a redundant filter
    # and decreases its counter if so.
    #
    # If a filter's counter has reached 0 the method returns true.
    #
    # @param    [String]    url
    # @param    [Block]     block   to be called for each match and be passed
    #                                   the count, regexp and url
    #
    # @return   [Bool]  true if the url is redundant, false otherwise
    #
    # @see #redundant
    #
    def redundant?( url, &block )
        redundant.each do |regexp, count|
            next if !(url =~ regexp)
            return true if count == 0

            block.call( count, regexp, url ) if block_given?

            redundant[regexp] -= 1
        end
        false
    end

    def auto_redundant_path?( url, &block )
        return false if !auto_redundant?
        @auto_redundant_h ||= Hash.new( 0 )

        h = "#{url.split( '?' ).first}#{Utilities.parse_query( url ).keys.sort}".hash

        if @auto_redundant_h[h] >= auto_redundant
            block.call( @auto_redundant_h[h] ) if block_given?
            return true
        end

        @auto_redundant_h[h] += 1
        false
    end

    def dom_depth_limit_reached?( page )
        Options.dom_depth_limit && page.dom.depth > Options.dom_depth_limit
    end

    #
    # Checks if the given string matches one of the configured {#exclude_pages} patterns.
    #
    # @param    [String]    body
    #
    # @return   [Bool]
    #   `true` if `body` matches an {#exclude_pages} pattern, `false` otherwise.
    #
    # @see #exclude_pages
    #
    def exclude_page?( body )
        Options.exclude_pages.each { |i| return true if body.to_s =~ i }
        false
    end

    def exclude_binaries?
        self.exclude_binaries
    end

    def auto_redundant?
        !!@auto_redundant
    end

    def fuzz_methods?
        self.fuzz_methods
    end

    def do_not_crawl
        self.link_count_limit = 0
    end

    def crawl
        self.link_count_limit = nil
    end

    def crawl?
        !link_count_limit || link_count_limit != 0
    end

    def link_count_limit_reached?( count )
        link_count_limit && link_count_limit.to_i > 0 && count >= link_count_limit
    end

    #
    # Normalizes and sets `url` as the target URL.
    #
    # @param    [String]    url     absolute URL of the targeted web app
    #
    # @return   [String]    normalized `url`
    #
    # @raise    [Error::InvalidURL]     If the given `url` is not valid.
    #
    def url=( url )
        return if !url

        require @dir['lib'] + 'ruby'
        require @dir['lib'] + 'support'
        require @dir['lib'] + 'utilities'

        parsed = Utilities.uri_parse( url.to_s )
        if !parsed || !parsed.absolute?
            fail Error::InvalidURL,
                 "Invalid URL argument, please provide a full absolute URL and try again."
        else
            if !no_protocol_for_url?
                if https_only? && parsed.scheme != 'https'
                    fail Error::InvalidURL,
                         "Invalid URL argument, the 'https-only' option requires"+
                             " an HTTPS URL."
                elsif !%w(http https).include?( parsed.scheme )
                    fail Error::InvalidURL,
                         "Invalid URL scheme, please provide an HTTP or HTTPS URL and try again."
                end
            end
        end

        @url = parsed.to_s
    end

    #
    # Enables auditing of element types.
    #
    # @param    [String, Symbol, Array] element_types [Allowed: links, forms, cookies, headers]
    #
    def audit( *element_types )
        element_types.flatten.compact.each do |type|
            begin
                self.send( "audit_#{type}=", true )
            rescue
                begin
                    self.send( "audit_#{type}s=", true )
                rescue
                end
            end
        end
        true
    end
    alias :audit= :audit

    #
    # Disables auditing of element types.
    #
    # @param    [String, Symbol, Array] element_types [Allowed: links, forms, cookies, headers]
    #
    def dont_audit( *element_types )
        element_types.flatten.compact.each do |type|
            begin
                self.send( "audit_#{type}=", false )
            rescue
                begin
                    self.send( "audit_#{type}s=", false )
                rescue
                end
            end
        end
        true
    end


    #
    # Get audit settings for the given element types.
    #
    # @param    [String, Symbol, Array] element_types [Allowed: links, forms, cookies, headers]
    #
    # @return   [Bool]
    #
    def audit?( *element_types )
        !element_types.flatten.compact.map do |type|
            !!begin
                self.send( "audit_#{type}" )
            rescue
                begin
                    self.send( "audit_#{type}s" )
                rescue
                end
            end
        end.uniq.include?( false )
    end

    #
    # Configures options via a Hash object
    #
    # @param    [Hash]  options     options to set
    #
    # @return   [TrueClass]
    #
    def set( options )
        options.each do |k, v|
            begin
                send( "#{k.to_s}=", v )
            rescue => e
                #ap e
                #ap e.backtrace
            end
        end
        true
    end

    # @param    [Hash]  data
    def datastore=( data )
        @datastore = Hash[data]
    end

    #
    # Sets the redundancy filters.
    #
    # Filter example:
    #    {
    #        # regexp           counter
    #        /calendar\.php/ => 5
    #        'gallery\.php' => '3'
    #    }
    #
    # @param     [Hash]  filters
    #
    def redundant=( filters )
        @redundant = if filters.is_a?( Array ) ||
            (filters.is_a?( Hash ) && (filters.keys & %w(regexp count)).size == 2)
            [filters].flatten.inject({})  do |h, filter|
                regexp = filter['regexp'].is_a?( Regexp ) ?
                    filter['regexp'] : Regexp.new( filter['regexp'].to_s )

                h.merge!( regexp => Integer( filter['count'] ) )
                h
            end
        else
            filters.inject({}) do |h, (regexp, counter)|
                regexp = regexp.is_a?( Regexp ) ? regexp : Regexp.new( regexp.to_s )
                h.merge!( regexp => Integer( counter ) )
                h
            end
        end
    end

    # these options need to contain Array<String>
    [ :exclude_cookies, :exclude_vectors, :mods, :restrict_paths,
      :extend_paths ].each do |m|
        define_method( "#{m}=".to_sym ) do |arg|
            arg = [arg].flatten.map { |s| s.to_s }
            instance_variable_set( "@#{m}".to_sym, arg )
        end
    end
    alias :modules :mods
    alias :modules= :mods=

    # these options need to contain Array<Regexp>
    [ :exclude_pages, :include, :exclude, :lsmod, :lsplat, :lsrep, :lsplug ].each do |m|
        define_method( "#{m}=".to_sym ) do |arg|
            arg = [arg].flatten.map { |s| s.is_a?( Regexp ) ? s : Regexp.new( s.to_s ) }
            instance_variable_set( "@#{m}".to_sym, arg )
        end
    end

    def parse( require_url = true )
        # Construct getops struct
        opts = GetoptLong.new(
            [ '--help',              '-h', GetoptLong::NO_ARGUMENT ],
            [ '--verbosity',         '-v', GetoptLong::NO_ARGUMENT ],
            [ '--only-positives',    '-k', GetoptLong::NO_ARGUMENT ],
            [ '--lsmod',                   GetoptLong::OPTIONAL_ARGUMENT ],
            [ '--lsrep',                   GetoptLong::OPTIONAL_ARGUMENT ],
            [ '--lsplat',                  GetoptLong::NO_ARGUMENT ],
            [ '--audit-links',       '-g', GetoptLong::NO_ARGUMENT ],
            [ '--audit-forms',       '-p', GetoptLong::NO_ARGUMENT ],
            [ '--audit-cookies',     '-c', GetoptLong::NO_ARGUMENT ],
            [ '--audit-cookie-jar',        GetoptLong::NO_ARGUMENT ],
            [ '--audit-headers',           GetoptLong::NO_ARGUMENT ],
            [ '--spider-first',            GetoptLong::NO_ARGUMENT ],
            [ '--obey-robots-txt',   '-o', GetoptLong::NO_ARGUMENT ],
            [ '--redundant',               GetoptLong::REQUIRED_ARGUMENT ],
            [ '--depth',             '-d', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--dom-depth',               GetoptLong::REQUIRED_ARGUMENT ],
            [ '--redirect-limit',    '-q', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--link-count',        '-u', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--mods',              '-m', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--modules',                 GetoptLong::REQUIRED_ARGUMENT ],
            [ '--report',                  GetoptLong::REQUIRED_ARGUMENT ],
            [ '--repload',                 GetoptLong::REQUIRED_ARGUMENT ],
            [ '--authed-by',               GetoptLong::REQUIRED_ARGUMENT ],
            [ '--load-profile',            GetoptLong::REQUIRED_ARGUMENT ],
            [ '--save-profile',            GetoptLong::REQUIRED_ARGUMENT ],
            [ '--show-profile',            GetoptLong::NO_ARGUMENT ],
            [ '--proxy',             '-z', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--proxy-auth',        '-x', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--proxy-type',        '-y', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--cookie-jar',        '-j', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--cookie-string'          , GetoptLong::REQUIRED_ARGUMENT ],
            [ '--user-agent',        '-b', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--exclude',           '-e', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--exclude-page',            GetoptLong::REQUIRED_ARGUMENT ],
            [ '--exclude-cookie',          GetoptLong::REQUIRED_ARGUMENT ],
            [ '--exclude-vector',          GetoptLong::REQUIRED_ARGUMENT ],
            [ '--include',           '-i', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--http-req-limit',          GetoptLong::REQUIRED_ARGUMENT ],
            [ '--http-timeout',            GetoptLong::REQUIRED_ARGUMENT ],
            [ '--follow-subdomains', '-f', GetoptLong::NO_ARGUMENT ],
            [ '--debug',             '-w', GetoptLong::NO_ARGUMENT ],
            [ '--server',                  GetoptLong::REQUIRED_ARGUMENT ],
            [ '--plugin',                  GetoptLong::OPTIONAL_ARGUMENT ],
            [ '--lsplug',                  GetoptLong::OPTIONAL_ARGUMENT ],
            [ '--serialized-opts',         GetoptLong::REQUIRED_ARGUMENT ],
            [ '--ssl',                     GetoptLong::NO_ARGUMENT ],
            [ '--ssl-pkey',                GetoptLong::REQUIRED_ARGUMENT ],
            [ '--ssl-cert',                GetoptLong::REQUIRED_ARGUMENT ],
            [ '--node-ssl-pkey',          GetoptLong::REQUIRED_ARGUMENT ],
            [ '--node-ssl-cert',          GetoptLong::REQUIRED_ARGUMENT ],
            [ '--ssl-ca',                 GetoptLong::REQUIRED_ARGUMENT ],
            [ '--address',                GetoptLong::REQUIRED_ARGUMENT ],
            [ '--reroute-to-logfile',     GetoptLong::NO_ARGUMENT ],
            [ '--pool-size',              GetoptLong::REQUIRED_ARGUMENT ],
            [ '--neighbour',              GetoptLong::REQUIRED_ARGUMENT ],
            [ '--weight',                 GetoptLong::REQUIRED_ARGUMENT ],
            [ '--cost',                   GetoptLong::REQUIRED_ARGUMENT ],
            [ '--pipe-id',                GetoptLong::REQUIRED_ARGUMENT ],
            [ '--nickname',               GetoptLong::REQUIRED_ARGUMENT ],
            [ '--username',               GetoptLong::REQUIRED_ARGUMENT ],
            [ '--password',               GetoptLong::REQUIRED_ARGUMENT ],
            [ '--port',                   GetoptLong::REQUIRED_ARGUMENT ],
            [ '--host',                   GetoptLong::REQUIRED_ARGUMENT ],
            [ '--custom-header',          GetoptLong::REQUIRED_ARGUMENT ],
            [ '--restrict-paths',         GetoptLong::REQUIRED_ARGUMENT ],
            [ '--extend-paths',           GetoptLong::REQUIRED_ARGUMENT ],
            [ '--port-range',             GetoptLong::REQUIRED_ARGUMENT ],
            [ '--http-harvest-last',      GetoptLong::NO_ARGUMENT ],
            [ '--fuzz-methods',           GetoptLong::NO_ARGUMENT ],
            [ '--audit-cookies-extensively',      GetoptLong::NO_ARGUMENT ],
            [ '--exclude-binaries',       GetoptLong::NO_ARGUMENT ],
            [ '--auto-redundant',         GetoptLong::OPTIONAL_ARGUMENT ],
            [ '--login-check-url',        GetoptLong::REQUIRED_ARGUMENT ],
            [ '--login-check-pattern',    GetoptLong::REQUIRED_ARGUMENT ],
            [ '--spawns',                 GetoptLong::REQUIRED_ARGUMENT ],
            [ '--grid',                   GetoptLong::NO_ARGUMENT ],
            [ '--grid-mode',              GetoptLong::REQUIRED_ARGUMENT ],
            [ '--http-username',          GetoptLong::REQUIRED_ARGUMENT ],
            [ '--http-password',          GetoptLong::REQUIRED_ARGUMENT ],
            [ '--https-only',             GetoptLong::NO_ARGUMENT ],
            [ '--no-fingerprinting',      GetoptLong::NO_ARGUMENT ],
            [ '--platforms',              GetoptLong::REQUIRED_ARGUMENT ],
            [ '--version',                GetoptLong::NO_ARGUMENT ]
        )

        opts.quiet = true

        begin
            opts.each do |opt, arg|

                case opt

                    when '--help'
                        @help = true

                    when '--version'
                        @version = true

                    when '--no-fingerprinting'
                        @no_fingerprinting = true

                    when '--platforms'
                        @platforms = arg.to_s.split( ',' )

                    when '--serialized-opts'
                        merge!( unserialize( arg ) )

                    when '--only-positives'
                        @only_positives = true

                    when '--verbosity'
                        @arachni_verbose = true

                    when '--debug'
                        @debug = true

                    when '--plugin'
                        plugin, opt_str = arg.split( ':', 2 )

                        opts = {}
                        if opt_str
                            opt_arr = opt_str.split( ',' )
                            opt_arr.each {
                                |c_opt|
                                name, val = c_opt.split( '=', 2 )
                                opts[name] = val
                            }
                        end

                        @plugins[plugin] = opts

                    when '--redundant'
                        regexp, counter = arg.to_s.split( ':', 2 )
                        @redundant[ Regexp.new( regexp ) ] = Integer( counter )

                    when '--port-range'
                        first, last = arg.to_s.split( '-' )
                        @rpc_instance_port_range = [ Integer( first ), Integer( last ) ]

                    when '--custom-header'
                        header, val = arg.to_s.split( /=/, 2 )
                        @custom_headers[header] = val

                    when '--restrict-paths'
                        @restrict_paths |= paths_from_file( arg )
                        @restrict_paths_filepath = arg

                    when '--extend-paths'
                        @extend_paths |= paths_from_file( arg )
                        @extend_paths_filepath = arg

                    when '--obey_robots_txt'
                        @obey_robots_txt = true

                    when '--depth'
                        @depth_limit = arg.to_i

                    when '--dom-depth'
                        @dom_depth_limit = arg.to_i

                    when '--link-count'
                        @link_count_limit = arg.to_i

                    when '--redirect-limit'
                        @redirect_limit = arg.to_i

                    when '--lsmod'
                        @lsmod << Regexp.new( arg.to_s )

                    when '--lsplug'
                        @lsplug << Regexp.new( arg.to_s )

                    when '--lsrep'
                        @lsrep << Regexp.new( arg.to_s )

                    when '--lsplat'
                        @lsplat = true

                    when '--http-req-limit'
                        @http_req_limit = arg.to_i

                    when '--http-timeout'
                        @http_timeout = arg.to_i

                    when '--audit-links'
                        @audit_links = true

                    when '--audit-forms'
                        @audit_forms = true

                    when '--audit-cookies'
                        @audit_cookies = true

                    when '--audit-cookie-jar'
                        @audit_cookie_jar = true

                    when '--audit-headers'
                        @audit_headers = true

                    when '--mods', '--modules'
                        @mods = arg.to_s.split( ',' )

                    when '--report'
                        report, opt_str = arg.split( ':' )

                        opts = {}
                        if opt_str
                            opt_arr = opt_str.split( ',' )
                            opt_arr.each {
                                |c_opt|
                                name, val = c_opt.split( '=' )
                                opts[name] = val
                            }
                        end

                        @reports[report] = opts

                    when '--repload'
                        @repload = arg

                    when '--save-profile'
                        @save_profile = arg

                    when '--load-profile'
                        @load_profile << arg

                    when '--show-profile'
                        @show_profile = true

                    when '--authed-by'
                        @authed_by = arg

                    when '--proxy'
                        @proxy_host, @proxy_port =
                            arg.to_s.split( /:/ )

                        @proxy_port = @proxy_port.to_i

                    when '--proxy-auth'
                        @proxy_username, @proxy_password =
                            arg.to_s.split( /:/ )

                    when '--proxy-type'
                        @proxy_type = arg.to_s

                    when '--cookie-jar'
                        @cookie_jar = arg.to_s

                    when '--cookie-string'
                        @cookie_string = arg.to_s

                    when '--user-agent'
                        @user_agent = arg.to_s

                    when '--exclude'
                        @exclude << Regexp.new( arg )

                    when '--exclude-page'
                        @exclude_pages << Regexp.new( arg )

                    when '--exclude-cookie'
                        @exclude_cookies << arg

                    when '--exclude-vector'
                        @exclude_vectors << arg

                    when '--include'
                        @include << Regexp.new( arg )

                    when '--follow-subdomains'
                        @follow_subdomains = true

                    when '--http-harvest-last'
                        puts 'The http-harvest-last option has been removed.'
                        puts 'Please adjust your command-line arguments and try again.'
                        exit

                    when '--ssl'
                        @ssl = true

                    when '--ssl-pkey'
                        @ssl_pkey = arg.to_s

                    when '--ssl-cert'
                        @ssl_cert = arg.to_s

                    when '--ssl-ca'
                        @ssl_ca = arg.to_s

                    when '--server'
                        @server = arg.to_s

                    when '--reroute-to-logfile'
                        @reroute_to_logfile = true

                    when '--port'
                        @rpc_port = arg.to_i

                    when '--address'
                        @rpc_address = arg.to_s

                    when '--pool-size'
                        @pool_size = arg.to_i

                    when '--neighbour'
                        @neighbour = arg.to_s

                    when '--cost'
                        @cost = arg.to_s

                    when '--weight'
                        @weight = arg.to_s

                    when '--pipe-id'
                        @pipe_id = arg.to_s

                    when '--nickname'
                        @nickname = arg.to_s

                    when '--host'
                        @server = arg.to_s

                    when '--fuzz-methods'
                        @fuzz_methods = true

                    when '--audit-cookies-extensively'
                        @audit_cookies_extensively = true

                    when '--exclude-binaries'
                        @exclude_binaries = true

                    when '--auto-redundant'
                        @auto_redundant = arg.empty? ? 10 : arg.to_i

                    when '--login-check-url'
                        @login_check_url = arg

                    when '--login-check-pattern'
                        @login_check_pattern = arg

                    when '--spawns'
                        @spawns = arg.to_i

                    when '--grid'
                        self.grid = true

                    when '--grid-mode'
                        self.grid_mode = arg

                    when '--https-only'
                        @https_only = true

                    when '--http-username'
                        @http_username = arg

                    when '--http-password'
                        @http_password = arg
                end
            end

            if (!@login_check_url && @login_check_pattern) ||
                (@login_check_url && !@login_check_pattern)
                fail Error, "Both '--login-check-url' and " +
                    "'--login-check-pattern' options are required."
            end

        rescue => e
            puts BANNER
            puts
            puts e
            exit
        end

        self.url = ARGV.shift if require_url
    end

    def no_protocol_for_url
        @no_protocol_for_url = true
    end

    def no_protocol_for_url?
        !!@no_protocol_for_url
    end

    # @return   [String]    root path of the framework
    def root_path
        File.dirname( File.dirname( File.dirname( File.expand_path( File.expand_path(  __FILE__  ) ) ) ) ) + '/'
    end

    #
    # @return   [String]    Single-line, Base64 encoded serialized version of self.
    #
    # @see #unserialize
    #
    def serialize
        Base64.encode64( to_yaml ).split( "\n" ).join
    end

    #
    # Unserializes what is returned by {#serialize}.
    #
    # @param    [String]    str return value of {#serialize}
    #
    # @return   [Arachni::Options]
    #
    # @see #serialize
    #
    def unserialize( str )
        YAML.load( Base64.decode64( str ) )
    end

    #
    # Saves 'self' to `file`
    #
    # @param    [String]    file
    #
    def save( file )

        dir = @dir.clone

        load_profile    = []
        save_profile    = nil
        authed_by       = nil
        restrict_paths  = []
        extend_paths    = []

        load_profile   = @load_profile.clone    if @load_profile
        save_profile   = @save_profile.clone    if @save_profile
        authed_by      = @authed_by.clone       if @authed_by
        restrict_paths = @restrict_paths.clone  if @restrict_paths
        extend_paths   = @extend_paths.clone    if @extend_paths

        @dir            = nil
        @load_profile   = []
        @save_profile   = nil
        @authed_by      = nil
        @restrict_paths = []
        @extend_paths   = []

        begin
            f = File.open( file, 'w' )
            YAML.dump( self, f )
        rescue
            return
        ensure
            f.close

            @dir          = dir
            @load_profile = load_profile
            @save_profile = save_profile
            @authed_by    = authed_by

            @restrict_paths = restrict_paths
            @extend_paths   = extend_paths
        end

        f.path
    end

    #
    # Loads a file created by {#save}.
    #
    # @param    [String]    filepath    path to the file created by {#save}
    #
    # @return   [Arachni::Options]
    #
    def load( filepath )
        opts = YAML::load( IO.read( filepath ) )

        if opts.restrict_paths_filepath
            opts.restrict_paths = paths_from_file( opts.restrict_paths_filepath )
        end

        if opts.extend_paths_filepath
            opts.extend_paths   = paths_from_file( opts.extend_paths_filepath )
        end

        opts
    end

    #
    # Converts the Options object to hash
    #
    # @return    [Hash]
    #
    def to_h
        hash = {}
        self.instance_variables.each do |var|
            hash[normalize_name( var )] = self.instance_variable_get( var )
        end
        hash
    end
    alias :to_hash :to_h

    #
    # Compares 2 {Arachni::Options} objects.
    #
    # @param    [Arachni::Options]  other
    #
    # @return   [Bool]  `true` if `self == other` `false` otherwise
    #
    def ==( other )
        to_hash == other.to_hash
    end

    #
    # Merges `self` with the object in `options` skipping `nils` and empty
    # `Array`s or `Hash`es.
    #
    # @param    [Arachni::Options, #to_hash]   options
    #
    # @return   [Arachni::Options]   Updated `self`.
    #
    def merge!( options )
        options.to_hash.each_pair do |k, v|
            next if !v
            next if ( v.is_a?( Array ) || v.is_a?( Hash ) ) && v.empty?
            send( "#{k.to_s}=", v )
        end
        self
    end

    def to_args
        ' ' + to_hash.map { |key, val| to_arg( key ) if val }.compact.join( ' ' ) + " #{self.url}"
    end

    def to_arg( key )

        do_not_parse = %w(show_profile url dir)

        var = self.instance_variable_get( "@#{key}" )

        return if !var
        return if ( var.is_a?( Array ) || var.is_a?( Hash ) ) && var.empty?
        return if do_not_parse.include?( key )
        return if key == 'include' && var == [/.*/]
        return if key == 'reports' && var.keys == %w(stdout)

        key = 'exclude_cookie' if key == 'exclude_cookies'
        key = 'exclude_vector' if key == 'exclude_vectors'
        key = 'report'         if key == 'reports'

        key = key.gsub( '_', '-' )

        arg = ''

        case key

            when 'mods'
                var = var.join( ',' )

            when 'restrict-paths'
                var = @restrict_paths_filepath

            when 'extend-paths'
                var = @extend_paths_filepath

            when 'rpc-instance-port-range'
                var = var.join( '-' )

            when 'arachni-verbose'
                key = 'verbosity'

            when 'redundant'
                var.each do |rule|
                    arg += " --#{key}=#{rule['regexp'].source}:#{rule['count']}"
                end
                return arg

            when 'plugins','report'
                arg = ''
                var.each do |opt, val|
                    arg += " --#{key.chomp( 's' )}=#{opt}"
                    arg += ':' if !val.empty?

                    val.each {
                        |k, v|
                        arg += "#{k}=#{v},"
                    }

                    arg.chomp!( ',' )
                end
                return arg

            when 'proxy-port'
                return

            when 'proxy-addr'
                return "--proxy=#{self.proxy_host}:#{self.proxy_port}"
        end

        if var.is_a?( TrueClass )
            arg = "--#{key}"
        elsif var.is_a?( String ) || var.is_a?( Fixnum )
            arg = "--#{key}=#{var.to_s}"
        elsif var.is_a?( Array )
            var.each do |i|
                i = i.source if i.is_a?( Regexp )
                arg += " --#{key}=#{i}"
            end
        end

        arg
    end

    def paths_from_file( file )
        IO.read( file ).lines.map { |p| p.strip }
    end

    def self.method_missing( sym, *args, &block )
        if instance.respond_to?( sym )
            instance.send( sym, *args, &block )
        elsif
            super( sym, *args, &block )
        end
    end

    def self.respond_to?( m )
        super( m ) || instance.respond_to?( m )
    end


    # Ruby 2.0 or YAML doesn't like my class-level method_missing for some reason
    class <<self
        public :allocate
    end

    private

    def normalize_name( name )
        name.to_s.gsub( '@', '' )
    end

end
end
