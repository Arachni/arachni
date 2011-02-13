=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'singleton'

module Arachni

#
# Options class.
#
# Implements the Singleton pattern and formaly defines
# all of Arachni's runtime options.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
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
    attr_accessor :url

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
    # If nil, link_count_limit = inf
    #
    # @return    [Integer]
    #
    attr_accessor :link_count_limit

    #
    # How many redirects to follow?
    # If nil, redirect_limit = inf
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

    attr_accessor :spider_first

    attr_accessor :rpc_port
    attr_accessor :ssl
    attr_accessor :ssl_pkey
    attr_accessor :ssl_cert
    attr_accessor :ssl_ca

    attr_accessor :server

    attr_accessor :reroute_to_logfile
    attr_accessor :pool_size


    def initialize( )

        # nil everything out
        self.instance_variables.each {
            |var|
            instance_variable_set( var.to_s, nil )
        }

        @exclude    = []
        @include    = []
        @redundant  = []

        @reports    = {}
        @lsrep      = []

        @lsmod      = []
        @dir        = Hash.new
        @exclude_cookies    = []
        @load_profile       = []

        @plugins = {}
        @lsplug  = []

        # set some defaults
        @redirect_limit = 20

        # relatively low but will give good performance without bottleneck
        # on low bandwidth conections
        @http_req_limit = 20

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

        @dir          = nil
        @load_profile = nil
        @save_profile = nil
        @authed_by    = nil

        begin
            f = File.open( file + PROFILE_EXT, 'w' )
            YAML.dump( self, f )
        rescue
            return
        ensure
            f.close

            @dir          = dir
            @load_profile = load_profile
            @save_profile = save_profile
            @authed_by    = authed_by
        end

        return f.path
    end

    def url=( str )
        return if !str

        require 'uri'
        require self.dir['lib'] + 'exceptions'
        require self.dir['lib'] + 'module/utilities'

        begin
            @url = URI( Arachni::Module::Utilities.normalize_url( str.to_s ) )
        rescue
            raise( Arachni::Exceptions::InvalidURL, "Invalid URL argument." )
        end

        return str
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

        var = self.instance_variable_get( "@#{key}" )

        return if !var
        return if ( var.is_a?( Array ) || var.is_a?( Hash ) ) && var.empty?
        return if key == 'show_profile'
        return if key == 'url'
        return if key == 'dir'
        return if key == 'include' && var == [/.*/]
        return if key == 'reports' && var == ['stdout']

        key = 'exclude_cookie' if key == 'exclude_cookies'
        key = 'report'         if key == 'reports'

        key = key.gsub( '_', '-' )

        arg = ''

        case key

            when 'mods'
                var = var.join( ',' )

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

    private

    def normalize_name( name )
        name.to_s.gsub( '@', '' )
    end


end
end
