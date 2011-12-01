=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'yaml'
YAML::ENGINE.yamler = 'syck'

require 'singleton'
require 'getoptlong'

module Arachni

#
# Options class.
#
# Implements the Singleton pattern and formally defines
# all of Arachni's runtime options.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
#
class Options

    include Singleton

    #
    # The extension of the profile files.
    #
    # @return    [String]
    #
    PROFILE_EXT = '.afp'

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

    attr_accessor :grid_mode

    #
    # @return   [String]    the URL of a neighbouring Dispatcher
    #
    attr_accessor :neighbour

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
    # @return    [String,URI]
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
    # Filters for redundant links
    #
    # @return    [Array]
    #
    attr_accessor :redundant

    #
    # Should the crawler obery robots.txt files?
    #
    # @return    [Bool]
    #
    attr_accessor :obey_robots_txt

    #
    # How deep to go in the site structure?<br/>
    # If nil, depth_limit = inf
    #
    # @return    [Integer]
    #
    attr_accessor :depth_limit

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
    attr_accessor :proxy_addr

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
    attr_accessor :proxy_pass

    #
    # The proxy user
    #
    # @return    [String]
    #
    attr_accessor :proxy_user

    #
    # The proxy type
    #
    # @return    [String]     [http, socks]
    #
    attr_accessor :proxy_type

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
    # The HTTP user-agent to use
    #
    # @return    [String]
    #
    attr_accessor :user_agent

    #
    # Exclude filters <br/>
    # URL matching any of these patterns won't be followed
    #
    # @return    [Array]
    #
    attr_accessor :exclude

    #
    # Cookies to exclude from audit<br/>
    #
    # @return    [Array]
    #
    attr_accessor :exclude_cookies

    #
    # Include filters <br/>
    # Only URLs that match any of these patterns will be followed
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

    #
    # Harvest the HTTP responses for the whole site at the end or
    # for each page?
    #
    # @return    [Bool]
    #
    attr_accessor :http_harvest_last

    # to be populated by the framework
    attr_accessor :start_datetime
    # to be populated by the framework
    attr_accessor :finish_datetime
    # to be populated by the framework
    attr_accessor :delta_time

    attr_accessor :lsplug
    attr_accessor :plugins

    attr_accessor :rpc_port
    attr_accessor :rpc_address

    attr_accessor :rpc_instance_port_range

    attr_accessor :ssl
    attr_accessor :ssl_pkey
    attr_accessor :ssl_cert
    attr_accessor :ssl_ca

    attr_accessor :server

    attr_accessor :reroute_to_logfile
    attr_accessor :pool_size

    attr_accessor :webui_username
    attr_accessor :webui_password

    attr_accessor :custom_headers

    attr_accessor :restrict_paths
    attr_accessor :restrict_paths_filepath

    attr_accessor :extend_paths
    attr_accessor :extend_paths_filepath

    attr_accessor :min_pages_per_instance
    attr_accessor :max_slaves


    def initialize
        reset!
    end

    def reset!
        # nil everything out
        self.instance_variables.each {
            |var|
            instance_variable_set( var.to_s, nil )
        }

        @dir            = {}
        @dir['root']    = root_path
        @dir['gfx']     = @dir['root'] + 'gfx/'
        @dir['conf']    = @dir['root'] + 'conf/'
        @dir['logs']    = @dir['root'] + 'logs/'
        @dir['data']    = @dir['root'] + 'data/'
        @dir['modules'] = @dir['root'] + 'modules/'
        @dir['reports'] = @dir['root'] + 'reports/'
        @dir['plugins'] = @dir['root'] + 'plugins/'
        @dir['path_extractors']    = @dir['root'] + 'path_extractors/'
        @dir['lib']     = @dir['root'] + 'lib/arachni/'
        @dir['arachni'] = @dir['lib'][0...-1]

        # we must add default values for everything because that can serve
        # both as a default configuration and as an inexpensive way to declare
        # their data types for later verification

        @datastore  = {}
        @grid_mode  = ''
        @neighbour  = ''
        @cost       = 0.0
        @pipe_id    = ''
        @weight     = 0.0
        @nickname   = ''

        @redundant  = []

        @obey_robots_txt = false

        @depth_limit      = -1
        @link_count_limit = -1
        @redirect_limit   = 20

        @lsmod      = []
        @lsrep      = []

        @http_req_limit = 20

        @audit_links = false
        @audit_forms = false
        @audit_cookies = false
        @audit_headers = false

        @mods = []

        @reports    = {}

        @authed_by = ''

        @exclude    = []
        @exclude_cookies    = []

        @include    = []

        @follow_subdomains = false
        @http_harvest_last = false


        @lsplug     = []
        @plugins    = {}

        @rpc_port    = 7331
        @rpc_address = 'localhost'

        @rpc_instance_port_range = [1025, 65535]

        @exclude_cookies    = []
        @load_profile       = []
        @restrict_paths     = []
        @extend_paths       = []
        @custom_headers     = {}

        @min_pages_per_instance = 30
        @max_slaves = 10
    end

    def parse!

        # Construct getops struct
        opts = GetoptLong.new(
            [ '--help',              '-h', GetoptLong::NO_ARGUMENT ],
            [ '--verbosity',         '-v', GetoptLong::NO_ARGUMENT ],
            [ '--only-positives',    '-k', GetoptLong::NO_ARGUMENT ],
            [ '--lsmod',                   GetoptLong::OPTIONAL_ARGUMENT ],
            [ '--lsrep',                   GetoptLong::OPTIONAL_ARGUMENT ],
            [ '--audit-links',       '-g', GetoptLong::NO_ARGUMENT ],
            [ '--audit-forms',       '-p', GetoptLong::NO_ARGUMENT ],
            [ '--audit-cookies',     '-c', GetoptLong::NO_ARGUMENT ],
            [ '--audit-cookie-jar',        GetoptLong::NO_ARGUMENT ],
            [ '--audit-headers',           GetoptLong::NO_ARGUMENT ],
            [ '--spider-first',            GetoptLong::NO_ARGUMENT ],
            [ '--obey-robots-txt',   '-o', GetoptLong::NO_ARGUMENT ],
            [ '--redundant',               GetoptLong::REQUIRED_ARGUMENT ],
            [ '--depth',             '-d', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--redirect-limit',    '-q', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--link-count',        '-u', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--mods',              '-m', GetoptLong::REQUIRED_ARGUMENT ],
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
            [ '--user-agent',        '-b', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--exclude',           '-e', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--include',           '-i', GetoptLong::REQUIRED_ARGUMENT ],
            [ '--exclude-cookie',          GetoptLong::REQUIRED_ARGUMENT ],
            [ '--http-req-limit',          GetoptLong::REQUIRED_ARGUMENT ],
            [ '--follow-subdomains', '-f', GetoptLong::NO_ARGUMENT ],
            [ '--http-harvest-last', '-s', GetoptLong::NO_ARGUMENT ],
            [ '--debug',             '-w', GetoptLong::NO_ARGUMENT ],
            [ '--server',                  GetoptLong::REQUIRED_ARGUMENT ],
            [ '--plugin',                  GetoptLong::OPTIONAL_ARGUMENT ],
            [ '--lsplug',                  GetoptLong::OPTIONAL_ARGUMENT ],
            [ '--ssl',                     GetoptLong::NO_ARGUMENT ],
            [ '--ssl-pkey',                GetoptLong::REQUIRED_ARGUMENT ],
            [ '--ssl-cert',                GetoptLong::REQUIRED_ARGUMENT ],
            [ '--ssl-ca',                  GetoptLong::REQUIRED_ARGUMENT ],
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
            [ '--port-range',             GetoptLong::REQUIRED_ARGUMENT ]
        )

        opts.quiet = true

        begin
            opts.each {
                |opt, arg|

                case opt

                    when '--help'
                        @help = true

                    when '--only-positives'
                        @only_positives = true

                    when '--verbosity'
                        @arachni_verbose = true

                    when '--debug'
                        @debug = true

                    when '--plugin'
                        plugin, opt_str = arg.split( ':', 2 )

                        opts = {}
                        if( opt_str )
                            opt_arr = opt_str.split( ',' )
                            opt_arr.each {
                                |c_opt|
                                name, val = c_opt.split( '=', 2 )
                                opts[name] = val
                            }
                        end

                        @plugins[plugin] = opts

                    when '--redundant'
                        @redundant << {
                            'regexp'  => Regexp.new( arg.to_s.split( /:/ )[0] ),
                            'count'   => Integer( arg.to_s.split( /:/ )[1] ),
                        }

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

                    when '--http-req-limit'
                      @http_req_limit = arg.to_i

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

                    when '--mods'
                        @mods = arg.to_s.split( /,/ )

                    when '--report'
                        report, opt_str = arg.split( ':' )

                        opts = {}
                        if( opt_str )
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
                        @proxy_addr, @proxy_port =
                            arg.to_s.split( /:/ )

                    when '--proxy-auth'
                        @proxy_user, @proxy_pass =
                            arg.to_s.split( /:/ )

                    when '--proxy-type'
                        @proxy_type = arg.to_s

                    when '--cookie-jar'
                        @cookie_jar = arg.to_s

                    when '--user-agent'
                        @user_agent = arg.to_s

                    when '--exclude'
                        @exclude << Regexp.new( arg )

                    when '--include'
                        @include << Regexp.new( arg )

                    when '--exclude-cookie'
                        @exclude_cookies << arg

                    when '--follow-subdomains'
                        @follow_subdomains = true

                    when '--http-harvest-last'
                        @http_harvest_last = true

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
                        options.server = arg.to_s

                    when '--username'
                        options.webui_username = arg.to_s

                    when '--password'
                        options.webui_password = arg.to_s

                end
            }
        rescue Exception => e
            puts e.inspect
            exit
        end

        self.url = ARGV.shift
    end

    def root_path
        File.dirname( File.dirname( File.dirname( File.expand_path( File.expand_path(  __FILE__  ) ) ) ) ) + '/'
    end

    #
    # Saves 'self' to file
    #
    # @param    [String]    file
    #
    def save( file )

        dir           = @dir.clone
        load_profile  = @load_profile.clone if @load_profile
        save_profile  = @save_profile.clone if @save_profile
        authed_by     = @authed_by.clone if @authed_by

        restrict_paths = @restrict_paths.clone if @restrict_paths
        extend_paths   = @extend_paths.clone if @extend_paths

        @dir          = nil
        @load_profile = nil
        @save_profile = nil
        @authed_by    = nil
        @restrict_paths = nil
        @extend_paths   = nil


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

        return f.path
    end

    def load( filename )
        opts = YAML::load( IO.read( filename ) )

        if opts.restrict_paths_filepath
            opts.restrict_paths = paths_from_file( opts.restrict_paths_filepath )
        end

        if opts.extend_paths_filepath
            opts.extend_paths   = paths_from_file( opts.extend_paths_filepath )
        end

        return opts
    end

    def url=( str )
        return if !str

        require 'uri'
        require @dir['lib'] + 'exceptions'
        require @dir['lib'] + 'module/utilities'

        begin
            @url = URI( Arachni::Module::Utilities.normalize_url( str.to_s ) )
        rescue Exception => e
            # ap e
            # ap e.backtrace
            raise( Arachni::Exceptions::InvalidURL, "Invalid URL argument." )
        end

        return str
    end

    def restrict_paths=( urls )
        @restrict_paths = [urls].flatten
    end

    #
    # Converts the Options object to hash
    #
    # @return    [Hash]
    #
    def to_h
        hash = Hash.new
        self.instance_variables.each {
            |var|
            hash[normalize_name( var )] = self.instance_variable_get( var )
        }
        hash
    end

    #
    # Merges self with the object in 'options'
    #
    # @param    [Options]
    #
    def merge!( options )
        options.to_h.each_pair {
            |k, v|

            next if ( v.is_a?( Array ) || v.is_a?( Hash ) ) && v.empty?
            send( "#{k}=", v ) if v
        }
    end

    def to_args

        cli_args = ''

        self.to_h.keys.each {
            |key|

            arg = self.to_arg( key )

            cli_args += " #{arg.to_s}" if arg
        }

        return cli_args += " #{self.url}"
    end

    def to_arg( key )

        do_not_parse = [
            'show_profile',
            'url',
            'dir',
        ]

        var = self.instance_variable_get( "@#{key}" )

        return if !var
        return if ( var.is_a?( Array ) || var.is_a?( Hash ) ) && var.empty?
        return if do_not_parse.include?( key )
        return if key == 'include' && var == [/.*/]
        return if key == 'reports' && var.keys == ['stdout']

        key = 'exclude_cookie' if key == 'exclude_cookies'
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
                var.each {
                    |rule|
                    arg += " --#{key}=#{rule['regexp'].source}:#{rule['count']}"
                }
                return arg

            when 'plugins','report'
                arg = ''
                var.each {
                    |opt, val|
                    arg += " --#{key.chomp( 's' )}=#{opt}"
                    arg += ':' if !val.empty?

                    val.each {
                        |k, v|
                        arg += "#{k}=#{v},"
                    }

                    arg.chomp!( ',' )
                }
                return arg

            when 'proxy-port'
                return

            when 'proxy-addr'
                return "--proxy=#{self.proxy_addr}:#{self.proxy_port}"


        end

        if( var.is_a?( TrueClass ) )
            arg = "--#{key}"
        end

        if( var.is_a?( String ) || var.is_a?( Fixnum ) )
            arg = "--#{key}=#{var.to_s}"
        end

        if( var.is_a?( Array ) )

            var.each {
                |i|

                i = i.source if i.is_a?( Regexp )

                arg += " --#{key}=#{i}"
            }

        end

        return arg
    end

    def paths_from_file( file )
        IO.read( file ).lines.map {
            |path|
            path.gsub!( "\n", '' )
            path.gsub!( "\r", '' )
            path
        }
    end

    private

    def normalize_name( name )
        name.to_s.gsub( '@', '' )
    end


end
end
