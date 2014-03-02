=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module HTTP

# HTTP Request representation.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Request < Message

    # Default redirect limit, RFC says 5 max.
    REDIRECT_LIMIT = 5

    # Supported modes of operation.
    MODES = [
        # Asynchronous (non-blocking) (Default)
        :async,

        # Synchronous (blocking)
        :sync
    ]

    # @return   [Integer]
    #   Auto-incremented ID for this request (set by {Client#request}).
    attr_accessor :id

    # @return [Hash]  Request parameters.
    attr_reader :parameters

    # @return [Integer] Timeout in milliseconds.
    attr_accessor :timeout

    # @return   [Bool]  Follow `Location` headers.
    attr_accessor :follow_location

    # @return   [Integer]   Maximum number of redirects to follow.
    # @see #follow_location
    attr_accessor :max_redirects

    # @return   [String]   HTTP username.
    attr_accessor :username

    # @return   [String]   HTTP password.
    attr_accessor :password

    # @return   [Hash]  Cookies set for this request.
    attr_reader :cookies

    # @return   [Symbol]
    #   Mode of operation for the request.
    #
    # @see MODES
    attr_reader :mode

    # Entity which performed the request -- mostly used to track which response
    # was a result of which submitted element.
    attr_accessor :performer

    # @private
    attr_accessor :root_redirect_id

    # @param  [Hash]  options    Request options.
    # @option options [String] :url URL.
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
        @max_redirects   = (Arachni::Options.http.request_redirect_limit || REDIRECT_LIMIT)
        @on_complete     = []

        @timeout       ||= Arachni::Options.http.request_timeout
        @mode          ||= :async
        @parameters    ||= {}
        @cookies       ||= {}
    end

    # @note All keys and values will be recursively converted to strings.
    #
    # @param  [Hash]  cookies
    #   Cookies to assign to this request.
    #
    # @return [Hash]  Normalized cookies.
    def cookies=( cookies )
        @cookies = cookies.stringify
    end

    # @note All keys and values will be recursively converted to strings.
    #
    # @param  [Hash]  params
    #   Parameters to assign to this request.
    #   If performing a GET request and the URL has parameters of its own they
    #   will be merged and overwritten.
    #
    # @return [Hash]  Normalized parameters.
    def parameters=( params )
        @parameters = params.stringify
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

    # @return [Symbol]  HTTP method.
    def method( *args )
        return super( *args ) if args.any? # Preserve Object#method.
        @method
    end

    # @note Method will be normalized to a lower-case symbol.
    #
    # Sets the request HTTP method.
    #
    # @param  [#to_s] verb HTTP method.
    #
    # @return [Symbol]  HTTP method.
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

    def handle_response( response )
        response.request = self
        @on_complete.each { |b| b.call response }
    end

    # @return [Typhoeus::Response] Converts self to a `Typhoeus::Response`.
    def to_typhoeus
        headers['Cookie'] = effective_cookies.
            map { |k, v| "#{Cookie.encode( k )}=#{Cookie.encode( v )}" }.
            join( ';' )

        headers.delete( 'Cookie' ) if headers['Cookie'].empty?
        headers.each { |k, v| headers[k] = Header.encode( v ) if v }

        if (userpwd = (@username || Arachni::Options.http.authentication_username))
            if (passwd = (@password || Arachni::Options.http.authentication_password))
                userpwd += ":#{passwd}"
            end
        end

        options = {
            method:          method,
            headers:         headers,
            body:            body,
            params:          Arachni::Utilities.parse_url_vars( url ).
                                 merge( parameters || {} ),
            userpwd:         userpwd,
            followlocation:  follow_location?,
            maxredirs:       @max_redirects,
            ssl_verifypeer:  false,
            ssl_verifyhost:  0,
            accept_encoding: 'gzip, deflate',
            nosignal:        true,
            maxfilesize:     @http_response_max_size || Arachni::Options.http.response_max_size,

            # Don't keep the socket alive if this is a blocking request because
            # it's going to be performed by an one-off Hydra.
            forbid_reuse:    blocking?
        }

        options[:timeout_ms] = timeout if timeout

        if Arachni::Options.http.proxy_host
            options.merge!(
                http_proxy:        "#{Arachni::Options.http.proxy_host}:#{Arachni::Options.http.proxy_port}",
                proxyuserpwd: "#{Arachni::Options.http.proxy_username}:#{Arachni::Options.http.proxy_password}",
                proxytype:    Arachni::Options.http.proxy_type
            )
        end

        curl = parsed_url.query ? url.gsub( "?#{parsed_url.query}", '' ) : url
        r = Typhoeus::Request.new( curl, options )
        r.on_complete do |typhoeus_response|
            handle_response Response.from_typhoeus( typhoeus_response )
        end
        r
    end

    def to_h
        {
            url:        url,
            parameters: parameters,
            headers:    headers,
            body:       body,
            method:     method
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
        performer = @performer ? @performer.dup : nil

        @performer   = nil
        @on_complete = []

        instance_variables.inject( {} ) do |h, iv|
            h[iv] = instance_variable_get( iv )
            h
        end
    ensure
        @on_complete = callbacks
        @performer   = performer.dup if performer
    end

    def marshal_load( h )
        h.each { |k, v| instance_variable_set( k, v ) }
    end
end
end
end
