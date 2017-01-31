=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

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
    include Utilities
    include UI::Output

    require_relative 'request/scope'

    ENCODE_CACHE = Support::Cache::LeastRecentlyPushed.new( 1_000 )

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

    # @return   [Array<Element::Cookie>]
    attr_reader   :raw_cookies

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

    # @return   [Array]
    #   Parameters which should not be encoded, by name.
    attr_accessor :raw_parameters

    # @return   [Response]
    attr_accessor :response

    # @private
    attr_accessor :response_body_buffer

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
        @fingerprint     = true  if @fingerprint.nil?
        @update_cookies  = false if @update_cookies.nil?
        @follow_location = false if @follow_location.nil?
        @max_redirects   = (Options.http.request_redirect_limit || REDIRECT_LIMIT)

        @on_headers    = []
        @on_body       = []
        @on_body_line  = []
        @on_body_lines = []
        @on_complete   = []

        @raw_parameters ||= []
        @timeout        ||= Options.http.request_timeout
        @mode           ||= :async
        @parameters     ||= {}
        @cookies        ||= {}
        @raw_cookies    ||= []
    end

    def raw_parameters=( names )
        if names
            @raw_parameters = names
        else
            @raw_parameters.clear
        end
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
        effective_cookies = self.cookies.dup

        if !headers['Cookie'].to_s.empty?
            Cookie.from_string( url, headers['Cookie'] ).
                inject( effective_cookies ) do |h, cookie|
                h[cookie.name] ||= cookie.value
                h
            end
        end

        @raw_cookies.inject( effective_cookies ) do |h, cookie|
            h[cookie.raw_name] ||= cookie.raw_value
            h
        end

        effective_cookies
    end

    def effective_parameters
        ep = Utilities.uri_parse_query( url )
        return ep if parameters.empty?

        ep.merge!( parameters )
    end

    def body_parameters
        return {}         if method != :post
        return parameters if parameters.any?

        if headers.content_type.to_s.start_with?( 'multipart/form-data' )
            return {} if !headers.content_type.include?( 'boundary=' )

            return Form.parse_data(
                body,
                headers.content_type.match( /boundary=(.*)/i )[1].to_s
            )
        end

        self.class.parse_body( body )
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

    def on_headers( &block )
        fail 'Block is missing.' if !block_given?
        @on_headers << block
        self
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

    def on_body( &block )
        fail 'Block is missing.' if !block_given?
        @on_body << block
        self
    end

    def on_body_line( &block )
        fail 'Block is missing.' if !block_given?
        @on_body_line << block
        self
    end

    def on_body_lines( &block )
        fail 'Block is missing.' if !block_given?
        @on_body_lines << block
        self
    end

    # Clears {#on_complete} callbacks.
    def clear_callbacks
        @on_complete.clear
        @on_body.clear
        @on_headers.clear
        @on_body_line.clear
        @on_body_lines.clear
    end

    # @return   [Bool]
    #   `true` if redirects should be followed, `false` otherwise.
    def follow_location?
        !!@follow_location
    end

    # @return   [Bool]
    #   `true` if the {Response} should be {Platform::Manager.fingerprint fingerprinted}
    #   for platforms, `false` otherwise.
    def fingerprint?
        @fingerprint
    end

    # @return   [Bool]
    #   `true` if the {Response} should be analyzed by the {Trainer}
    #   for new elements, `false` otherwise.
    def train?
        @train
    end

    def buffered?
        @on_body.any? || @on_body_line.any? || @on_body_lines.any?
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
        client_run
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

        ep = self.class.encode_hash( self.effective_parameters, @raw_parameters )

        eb = self.body
        if eb.is_a?( Hash )
            eb = self.class.encode_hash( eb, @raw_parameters )
        end

        options = {
            method:          method,
            headers:         headers,

            body:            eb,
            params:          ep,

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

            # If Content-Length is missing this option will have no effect, so
            # we'll also stream the body to make sure that we can at least abort
            # the reading of the response body if it exceeds this limit.
            maxfilesize:     max_size,

            # Reusing connections for blocking requests used to cause FD leaks
            # but doesn't appear to do so anymore.
            #
            # Let's allow reuse for all request types again but keep an eye on it.
            # forbid_reuse:    blocking?,

            # Enable debugging messages in order to capture raw traffic data.
            verbose:         true,

            # We're going to be escaping **a lot** of the same strings during
            # the scan, so bypass Ethon's encoding and do our own cache-based
            # encoding.
            escape:          false
        }

        options[:timeout_ms] = timeout if timeout

        # This will allow GSS-Negotiate to work out of the box but shouldn't
        # have any adverse effects.
        if !options[:userpwd] && !parsed_url.user
            options[:userpwd]  = ':'
            options[:httpauth] = :gssnegotiate
        else
            options[:httpauth] = Options.http.authentication_type.to_sym
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

        typhoeus_request = Typhoeus::Request.new( url.split( '?').first, options )

        aborted = nil

        # Always set this because we'll be streaming most of the time, so we
        # should set @response so that there'll be a response available for the
        # #on_body and #on_body_line callbacks.
        typhoeus_request.on_headers do |typhoeus_response|
            next aborted if aborted

            set_response_data typhoeus_response

            @on_headers.each do |on_header|
                exception_jail false do
                    if on_header.call( self.response ) == :abort
                        break aborted = :abort
                    end
                end

                next aborted if aborted
            end
        end

        if @on_body.any?
            typhoeus_request.on_body do |chunk|
                next aborted if aborted

                @on_body.each do |b|
                    exception_jail false do
                        chunk.recode!
                        if b.call( chunk, self.response ) == :abort
                            break aborted = :abort
                        end
                    end
                end

                next aborted if aborted
            end
        end

        if @on_body_line.any?
            line_buffer = ''
            typhoeus_request.on_body do |chunk|
                next aborted if aborted

                chunk.recode!
                line_buffer << chunk

                lines = line_buffer.lines

                @response_body_buffer = nil

                # Incomplete last line, we've either read everything of were cut
                # short, but we can't know which.
                if !lines.last.index( /[\n\r]/, -1 )
                    last_line = lines.pop

                    # Set it as the generic body buffer in order to be accessible
                    # via #on_complete in case this was indeed the end of the
                    # response.
                    @response_body_buffer = last_line.dup

                    # Also push it back to out own buffer in case there's more
                    # to read in order to complete the line.
                    line_buffer = last_line
                end

                lines.each do |line|
                    @on_body_line.each do |b|
                        exception_jail false do
                            if b.call( line, self.response ) == :abort
                                break aborted = :abort
                            end
                        end
                    end

                    break aborted if aborted
                end

                line_buffer.clear

                next aborted if aborted
            end
        end

        if @on_body_lines.any?
            lines_buffer = ''
            typhoeus_request.on_body do |chunk|
                next aborted if aborted

                chunk.recode!
                lines_buffer << chunk

                lines, middle, remnant = lines_buffer.rpartition( /[\r\n]/ )
                lines << middle

                @response_body_buffer = nil

                # Incomplete last line, we've either read everything of were cut
                # short, but we can't know which.
                if !remnant.empty?
                    # Set it as the generic body buffer in order to be accessible
                    # via #on_complete in case this was indeed the end of the
                    # response.
                    @response_body_buffer = remnant.dup

                    # Also push it back to out own buffer in case there's more
                    # to read in order to complete the line.
                    lines_buffer = remnant
                end

                @on_body_lines.each do |b|
                    exception_jail false do
                        if b.call( lines, self.response ) == :abort
                            break aborted = :abort
                        end
                    end
                end

                next aborted if aborted
            end
        end

        if @on_complete.any?
            # No need to set our own reader in order to enforce max response size
            # if the response is already been read bit by bit via other callbacks.
            if typhoeus_request.options[:maxfilesize] && @on_body.empty? &&
                @on_body_line.empty? && @on_body_lines.empty?

                @response_body_buffer = ''
                set_body_reader( typhoeus_request, @response_body_buffer )
            end

            typhoeus_request.on_complete do |typhoeus_response|
                next aborted if aborted

                # Set either by the default body reader or is a remnant from
                # a user specified callback like #on_body, #on_body_line, etc.
                if @response_body_buffer
                    typhoeus_response.options[:response_body] =
                        @response_body_buffer
                end

                set_response_data typhoeus_response

                @on_complete.each do |b|
                    exception_jail false do
                        b.call self.response
                    end
                end
            end
        end

        typhoeus_request
    end

    def set_response_data( typhoeus_response )
        fill_in_data_from_typhoeus_response typhoeus_response

        self.response = Response.from_typhoeus(
            typhoeus_response,
            normalize_url: @normalize_url,
            request:       self
        )

        self.response.update_from_typhoeus typhoeus_response
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
        raw_cookies   = @raw_cookies.dup
        callbacks     = @on_complete.dup
        on_body       = @on_body.dup
        on_headers    = @on_headers.dup
        on_body_line  = @on_body_line.dup
        on_body_lines = @on_body_lines.dup
        performer     = @performer
        response      = @response

        @performer     = nil
        @response      = nil
        @raw_cookies   = []
        @on_complete   = []
        @on_body       = []
        @on_body_line  = []
        @on_body_lines = []
        @on_headers    = []

        instance_variables.inject( {} ) do |h, iv|
            next h if iv == :@scope
            h[iv.to_s.gsub('@','')] = instance_variable_get( iv )
            h
        end
    ensure
        @response      = response
        @raw_cookies   = raw_cookies
        @on_complete   = callbacks
        @on_body       = on_body
        @on_body_line  = on_body_line
        @on_body_lines = on_body_lines
        @on_headers    = on_headers
        @performer     = performer
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
            return {} if body.to_s.empty?

            body.split( '&' ).inject( {} ) do |h, pair|
                name, value = pair.split( '=', 2 )
                h[Form.decode( name.to_s )] = Form.decode( value )
                h
            end
        end

        def encode_hash( hash, skip = [] )
            hash.inject({}) do |h, (k, v)|

                if skip.include?( k )
                    # We need to at least encode null-bytes since they can't
                    # be transported at all.
                    # If we don't Typhoeus/Ethon will raise errors.
                    h.merge!( encode_null_byte( k ) => encode_null_byte( v ) )
                else
                    h.merge!( encode( k ) => encode( v ) )
                end

                h
            end
        end

        def encode_null_byte( string )
            string.to_s.gsub "\0", '%00'
        end

        def encode( string )
            string = string.to_s
            @easy ||= Ethon::Easy.new( url: 'www.example.com' )
            ENCODE_CACHE.fetch( string ) { @easy.escape( string ) }
        end
    end

    def prepare_headers
        headers['User-Agent']      ||= Options.http.user_agent
        headers['Accept']          ||= 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
        headers['From']            ||= Options.authorized_by if Options.authorized_by
        headers['Accept-Language'] ||= 'en-US,en;q=0.8,he;q=0.6'

        headers.each { |k, v| headers[k] = Header.encode( v ) if v }

        final_cookies_hash = self.cookies
        final_raw_cookies  = self.raw_cookies

        if headers['Cookie']
            final_raw_cookies_set = Set.new( final_raw_cookies.map(&:name) )
            final_raw_cookies |= Cookie.from_string( url, headers['Cookie'] ).reject do |c|
                final_cookies_hash.include?( c.name ) ||
                    final_raw_cookies_set.include?( c.name )
            end
        end

        headers['Cookie'] = final_cookies_hash.
            map { |k, v| "#{Cookie.encode( k )}=#{Cookie.encode( v )}" }.join( ';' )

        if !headers['Cookie'].empty? && final_raw_cookies.any?
            headers['Cookie'] += ';'
        end

        headers['Cookie'] += final_raw_cookies.map { |c| c.to_s }.join( ';' )

        headers.delete( 'Cookie' ) if headers['Cookie'].empty?

        headers
    end

    private

    def client_run
        # Set #on_complete so that the #response will be set.
        on_complete {}
        to_typhoeus.run
        self.response
    end

    def fill_in_data_from_typhoeus_response( response )
        # Only grab the last data.
        # In case of CONNECT calls for HTTPS via proxy the first data will be
        # the proxy-related stuff.
        @headers_string = response.debug_info.header_out.last
        @effective_body = response.debug_info.data_out.last
    end

    def set_body_reader( typhoeus_request, buffer )
        return if !typhoeus_request.options[:maxfilesize]

        aborted = nil
        typhoeus_request.on_body do |chunk|
            next aborted if aborted

            if buffer.size >= typhoeus_request.options[:maxfilesize]
                buffer.clear
                next aborted = :abort
            end

            buffer << chunk

            true
        end
    end

end
end
end
