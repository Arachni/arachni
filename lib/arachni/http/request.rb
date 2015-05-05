=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module HTTP

# HTTP Request representation.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Request < Message
    require_relative 'request/scope'

    # Default redirect limit, RFC says 5 max.
    REDIRECT_LIMIT = 5

    # Supported modes of operation.
    MODES = [
        # Asynchronous (non-blocking) (Default)
        :async,

        # Synchronous (blocking)
        :sync
    ]

    # @return     [Integer]
    #   Auto-incremented ID for this request (set by {Client#request}).
    attr_accessor :id

    # @return   [Hash]
    #   Request parameters.
    attr_reader   :parameters

    # @return   [Integer]
    #   Timeout in milliseconds.
    attr_accessor :timeout

    # @return   [Bool]
    #   Follow `Location` headers.
    attr_accessor :follow_location

    # @return   [Integer]
    #   Maximum number of redirects to follow.
    #
    # @see #follow_location
    attr_accessor :max_redirects

    # @return   [String]
    #   HTTP username.
    attr_accessor :username

    # @return   [String]
    #   HTTP password.
    attr_accessor :password

    # @return   [Hash]
    #   Cookies set for this request.
    attr_reader   :cookies

    # @return   [Symbol]
    #   Mode of operation for the request.
    #
    # @see MODES
    attr_reader   :mode

    # @note Available only via completed {Response#request}.
    #
    # @return   [String]
    #   Transmitted HTTP request headers.
    attr_accessor :headers_string

    # @note Available only via completed {Response#request}.
    #
    # @return   [String]
    #   Transmitted HTTP request body.
    attr_accessor :effective_body

    # Entity which performed the request -- mostly used to track which response
    # was a result of which submitted element.
    attr_accessor :performer

    # @return   [String]
    #   `host:port`
    attr_accessor :proxy

    # @return   [String]
    #   `user:password`
    attr_accessor :proxy_user_password

    # @return   [String]
    attr_accessor :proxy_type

    # @return   [Bool]
    attr_accessor :high_priority

    # @return   [Integer]
    #   Maximum HTTP response size to accept, in bytes.
    attr_accessor :response_max_size

    # @private
    attr_accessor :root_redirect_id

    # @param  [Hash]  options
    #   Request options.
    # @option options [String] :url
    #   URL.
    # @option options [Hash]  :parameters ({})
    #   Request parameters.
    # @option options [String]  :body ({})
    #   Request body.
    # @option options [Bool]  :train   (false)
    #   Force Arachni to analyze the response looking for new elements.
    # @option options [Symbol]  :mode   (:async)
    #   Mode in which to perform the request:
    #
    #   * `:async` -- Asynchronous (non-blocking) (Default).
    #   * `:sync` -- Synchronous (blocking).
    # @option options [Hash]  :headers ({})
    #   Extra HTTP request headers.
    # @option options [Hash]  :cookies ({})
    #   Cookies for the request.
    def initialize( options = {} )
        options[:method] ||= :get

        super( options )

        @train           = false if @train.nil?
        @update_cookies  = false if @update_cookies.nil?
        @follow_location = false if @follow_location.nil?
        @max_redirects   = (Options.http.request_redirect_limit || REDIRECT_LIMIT)
        @on_complete     = []

        @timeout       ||= Options.http.request_timeout
        @mode          ||= :async
        @parameters    ||= {}
        @cookies       ||= {}
    end

    def high_priority?
        !!@high_priority
    end

    # @note All keys and values will be recursively converted to strings.
    #
    # @param  [Hash]  cookies
    #   Cookies to assign to this request.
    #
    # @return [Hash]  Normalized cookies.
    def cookies=( cookies )
        @cookies = cookies.stringify_recursively_and_freeze
    end

    # @note All keys and values will be recursively converted to strings.
    #
    # @param    [Hash]  params
    #   Parameters to assign to this request.
    #   If performing a GET request and the URL has parameters of its own they
    #   will be merged and overwritten.
    #
    # @return   [Hash]
    #   Normalized parameters.
    def parameters=( params )
        @parameters = params.stringify_recursively_and_freeze
    end

    # @return   [Boolean]
    #   `true` if {#mode} is `:async`, `false` otherwise.
    def asynchronous?
        mode == :async
    end

    # @return   [Boolean]
    #   `true` if {#mode} is `:sync`, `false` otherwise.
    def blocking?
        mode == :sync
    end

    # @return   [Symbol]
    #   HTTP method.
    def method( *args )
        return super( *args ) if args.any? # Preserve Object#method.
        @method
    end

    # @note Method will be normalized to a lower-case symbol.
    #
    # Sets the request HTTP method.
    #
    # @param    [#to_s] verb
    #   HTTP method.
    #
    # @return   [Symbol]
    #   HTTP method.
    def method=( verb )
        @method = verb.to_s.downcase.to_sym
    end

    def mode=( v )
        v = v.downcase.to_sym

        if !MODES.include?( v )
            fail ArgumentError,
                 "Invalid mode, supported modes are: #{MODES.join( ', ' )}"
        end

        @mode = v.to_sym
    end

    def effective_cookies
        Cookie.from_string( url, headers['Cookie'] || '' ).inject({}) do |h, cookie|
            h[cookie.name] = cookie.value
            h
        end.merge( cookies )
    end

    def effective_parameters
        Utilities.uri_parse_query( url ).merge( parameters || {} )
    end

    def body_parameters
        return {} if method != :post
        parameters.any? ? parameters : self.class.parse_body( body )
    end

    # @return   [String]
    #   HTTP request string.
    def to_s
        "#{headers_string}#{effective_body}"
    end

    def inspect
        s = "#<#{self.class} "
        s << "@id=#{id} "
        s << "@mode=#{mode} "
        s << "@method=#{method} "
        s << "@url=#{url.inspect} "
        s << "@parameters=#{parameters.inspect} "
        s << "@high_priority=#{high_priority} "
        s << "@performer=#{performer.inspect}"
        s << '>'
    end

    # @note Can be invoked multiple times.
    #
    # @param    [Block] block
    #   Callback to be passed the {Response response}.
    def on_complete( &block )
        fail 'Block is missing.' if !block_given?
        @on_complete << block
        self
    end

    # Clears {#on_complete} callbacks.
    def clear_callbacks
        @on_complete.clear
    end

    # @return   [Bool]
    #   `true` if redirects should be followed, `false` otherwise.
    def follow_location?
        !!@follow_location
    end

    # @return   [Bool]
    #   `true` if the {Response} should be analyzed by the {Trainer}
    #   for new elements, `false` otherwise.
    def train?
        @train
    end

    # Flags that the response should be analyzed by the {Trainer} for new
    # elements.
    def train
        @train = true
    end

    # @return   [Bool]
    #   `true` if the {CookieJar} should be updated with the {Response} cookies,
    #   `false` otherwise.
    def update_cookies?
        @update_cookies
    end

    # Flags that the {CookieJar} should be updated with the {Response} cookies.
    def update_cookies
        @update_cookies = true
    end

    # @note Will call {#on_complete} callbacks.
    #
    # Performs the {Request} without going through {HTTP::Client}.
    #
    # @return   [Response]
    def run
        client_run.tap { |r| r.request = self }
    end

    def handle_response( response )
        response.request = self
        @on_complete.each { |b| b.call response }
        response
    end

    # @return   [Typhoeus::Response]
    #   `self` converted to a `Typhoeus::Request`.
    def to_typhoeus
        prepare_headers

        if (userpwd = (@username || Options.http.authentication_username))
            if (passwd = (@password || Options.http.authentication_password))
                userpwd += ":#{passwd}"
            end
        end

        max_size = @response_max_size || Options.http.response_max_size
        # Weird I know, for some reason 0 gets ignored.
        max_size = 1   if max_size == 0
        max_size = nil if max_size < 0

        options = {
            method:          method,
            headers:         headers,
            body:            body,
            params:          effective_parameters,
            userpwd:         userpwd,
            followlocation:  follow_location?,
            maxredirs:       @max_redirects,

            ssl_verifypeer:  !!Options.http.ssl_verify_peer,
            ssl_verifyhost:  Options.http.ssl_verify_host ? 2 : 0,
            sslcert:         Options.http.ssl_certificate_filepath,
            sslcerttype:     Options.http.ssl_certificate_type,
            sslkey:          Options.http.ssl_key_filepath,
            sslkeytype:      Options.http.ssl_key_type,
            sslkeypasswd:    Options.http.ssl_key_password,
            cainfo:          Options.http.ssl_ca_filepath,
            capath:          Options.http.ssl_ca_directory,
            sslversion:      Options.http.ssl_version,

            accept_encoding: 'gzip, deflate',
            nosignal:        true,
            maxfilesize:     max_size,

            # Don't keep the socket alive if this is a blocking request because
            # it's going to be performed by an one-off Hydra.
            forbid_reuse:    blocking?,
            verbose:         true
        }

        options[:timeout_ms] = timeout if timeout

        # This will allow GSS-Negotiate to work out of the box but shouldn't
        # have any adverse effects.
        if !options[:userpwd] && !parsed_url.user
            options[:userpwd]  = ':'
            options[:httpauth] = :gssnegotiate
        else
            options[:httpauth] = :auto
        end

        if proxy
            options.merge!(
                proxy:     proxy,
                proxytype: (proxy_type || :http).to_sym
            )

            if proxy_user_password
                options[:proxyuserpwd] = proxy_user_password
            end

        elsif Options.http.proxy_host && Options.http.proxy_port
            options.merge!(
                proxy:     "#{Options.http.proxy_host}:#{Options.http.proxy_port}",
                proxytype: (Options.http.proxy_type || :http).to_sym
            )

            if Options.http.proxy_username && Options.http.proxy_password
                options[:proxyuserpwd] =
                    "#{Options.http.proxy_username}:#{Options.http.proxy_password}"
            end
        end

        curl = parsed_url.query ? url.gsub( "?#{parsed_url.query}", '' ) : url
        r = Typhoeus::Request.new( curl, options )

        if @on_complete.any?
            r.on_complete do |typhoeus_response|
                fill_in_data_from_typhoeus_response typhoeus_response
                handle_response Response.from_typhoeus( typhoeus_response )
            end
        end

        r
    end

    def to_h
        {
            url:            url,
            parameters:     parameters,
            headers:        headers,
            headers_string: headers_string,
            effective_body: effective_body,
            body:           body,
            method:         method
        }
    end

    def ==( other )
        hash == other.hash
    end

    def hash
        to_h.hash
    end

    def marshal_dump
        callbacks = @on_complete.dup
        performer = @performer

        @performer   = nil
        @on_complete = []

        instance_variables.inject( {} ) do |h, iv|
            next h if iv == :@scope
            h[iv.to_s.gsub('@','')] = instance_variable_get( iv )
            h
        end
    ensure
        @on_complete = callbacks
        @performer   = performer
    end

    def marshal_load( h )
        h.each { |k, v| instance_variable_set( "@#{k}", v ) }
    end

    # @return   [Hash]
    #   Data representing this instance that are suitable the RPC transmission.
    def to_rpc_data
        marshal_dump
    end

    class <<self

        # @param    [Hash]  data    {#to_rpc_data}
        # @return   [Request]
        def from_rpc_data( data )
            instance = allocate
            data.each do |name, value|

                value = case name
                            when 'method', 'mode'
                                value.to_sym

                            else
                                value
                        end

                instance.instance_variable_set( "@#{name}", value )
            end
            instance
        end

        # Parses an HTTP request body generated by submitting a form.
        #
        # @param    [String]    body
        #
        # @return   [Hash]
        #   Parameters.
        def parse_body( body )
            return {} if !body

            body.to_s.split( '&' ).inject( {} ) do |h, pair|
                name, value = pair.split( '=', 2 )
                h[Form.decode( name.to_s )] = Form.decode( value )
                h
            end
        end
    end

    def prepare_headers
        headers['Cookie'] = effective_cookies.
            map { |k, v| "#{Cookie.encode( k )}=#{Cookie.encode( v )}" }.
            join( ';' )
        headers.delete( 'Cookie' ) if headers['Cookie'].empty?

        headers['User-Agent'] ||= Options.http.user_agent
        headers['Accept']     ||= 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
        headers['From']       ||= Options.authorized_by if Options.authorized_by

        headers.each { |k, v| headers[k] = Header.encode( v ) if v }
    end

    private

    def fill_in_data_from_typhoeus_response( response )
        @headers_string = response.debug_info.header_out.first
        @effective_body = response.debug_info.data_out.first
    end

    def client_run
        response = to_typhoeus.run
        fill_in_data_from_typhoeus_response response

        Response.from_typhoeus( response )
    end

end
end
end
