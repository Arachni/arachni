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

    # @return   [String]    `host:port`
    attr_accessor :proxy

    # @return   [String]    `user:password`
    attr_accessor :proxyuserpwd

    # @return   [String]
    attr_accessor :proxytype

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
        @cookies = cookies.stringify_recursively_and_freeze
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

    # @return   [String]
    #   HTTP request string.
    def to_s
        "#{headers_string}#{effective_body}"
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
        response = to_typhoeus.run
        fill_in_data_from_typhoeus_response response

        Response.from_typhoeus( response ).tap { |r| r.request = self }
    end

    def handle_response( response, typhoeus_response = nil )
        if typhoeus_response
            fill_in_data_from_typhoeus_response typhoeus_response
        end

        response.request = self
        @on_complete.each { |b| b.call response }
        response
    end

    # @return [Typhoeus::Response] Converts self to a `Typhoeus::Response`.
    def to_typhoeus
        headers['Cookie'] = effective_cookies.
            map { |k, v| "#{Cookie.encode( k )}=#{Cookie.encode( v )}" }.
            join( ';' )

        headers['User-Agent'] ||= Arachni::Options.http.user_agent
        headers['Accept']     ||= 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
        headers['From']       ||= Arachni::Options.authorized_by if Arachni::Options.authorized_by

        headers.delete( 'Cookie' ) if headers['Cookie'].empty?
        headers.each { |k, v| headers[k] = Header.encode( v ) if v }

        if (userpwd = (@username || Arachni::Options.http.authentication_username))
            if (passwd = (@password || Arachni::Options.http.authentication_password))
                userpwd += ":#{passwd}"
            end
        end

        max_size = @response_max_size || Arachni::Options.http.response_max_size
        # Weird I know, for some reason 0 gets ignored.
        max_size = 1 if max_size == 0

        options = {
            method:          method,
            headers:         headers,
            body:            body,
            params:          Arachni::Utilities.link_parse_query( url ).
                                 merge( parameters || {} ),
            userpwd:         userpwd,
            followlocation:  follow_location?,
            maxredirs:       @max_redirects,
            ssl_verifypeer:  false,
            ssl_verifyhost:  0,
            accept_encoding: 'gzip, deflate',
            nosignal:        true,
            maxfilesize:     max_size,

            # Don't keep the socket alive if this is a blocking request because
            # it's going to be performed by an one-off Hydra.
            forbid_reuse:    blocking?,
            verbose:         true
        }

        options[:timeout_ms] = timeout if timeout

        if @proxy
            options.merge!(
                proxy:        proxy,
                proxyuserpwd: proxyuserpwd,
                proxytype:    proxytype
            )
        elsif Arachni::Options.http.proxy_host
            options.merge!(
                proxy:        "#{Arachni::Options.http.proxy_host}:#{Arachni::Options.http.proxy_port}",
                proxyuserpwd: "#{Arachni::Options.http.proxy_username}:#{Arachni::Options.http.proxy_password}",
                proxytype:    Arachni::Options.http.proxy_type
            )
        end

        curl = parsed_url.query ? url.gsub( "?#{parsed_url.query}", '' ) : url
        r = Typhoeus::Request.new( curl, options )

        if @on_complete.any?
            r.on_complete do |typhoeus_response|
                handle_response Response.from_typhoeus( typhoeus_response ), typhoeus_response
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
        performer = @performer ? @performer.dup : nil

        @performer   = nil
        @on_complete = []

        instance_variables.inject( {} ) do |h, iv|
            h[iv.to_s.gsub('@','')] = instance_variable_get( iv )
            h
        end
    ensure
        @on_complete = callbacks
        @performer   = performer.dup if performer
    end

    def marshal_load( h )
        h.each { |k, v| instance_variable_set( "@#{k}", v ) }
    end

    # @return   [Hash]
    #   Data representing this instance that are suitable the RPC transmission.
    def to_rpc_data
        marshal_dump
    end

    # @param    [Hash]  data    {#to_rpc_data}
    # @return   [Request]
    def self.from_rpc_data( data )
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

    private

    def fill_in_data_from_typhoeus_response( response )
        @headers_string = response.debug_info.header_out.first
        @effective_body = response.debug_info.data_out.first
    end

end
end
end
