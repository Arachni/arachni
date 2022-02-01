=begin
    Copyright 2010-2022 Ecsypno <http://www.ecsypno.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'cookie'

module Arachni::Element

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class NestedCookie < Base

    # Load and include all cookie-specific capability overrides.
    lib = "#{File.dirname( __FILE__ )}/#{File.basename(__FILE__, '.rb')}/capabilities/**/*.rb"
    Dir.glob( lib ).each { |f| require f }

    include Arachni::Element::Capabilities::Inputtable
    include Arachni::Element::Capabilities::Mutable
    include Arachni::Element::Capabilities::Auditable
    include Arachni::Element::Capabilities::Auditable::Buffered
    include Arachni::Element::Capabilities::Auditable::LineBuffered
    include Arachni::Element::Capabilities::Analyzable
    include Arachni::Element::Capabilities::WithSource

    include Capabilities::Submittable

    # Default cookie values
    DEFAULT = Cookie::DEFAULT

    attr_reader :data

    # @param    [Hash]  options
    #   For options see {DEFAULT}, with the following extras:
    # @option   options [String]    :url
    #   URL of the page which created the cookie -- **required**.
    # @option   options [String]     :action
    #   URL of the page to submit the cookie -- defaults to `:url`.
    # @option   options [Hash]     :inputs
    #   Allows you to pass cookie data as a `name => value` pair instead of the
    #   more complex {DEFAULT} structure.
    def initialize( options )
        @data = {}
        super( options )

        if options[:name] && options[:value]
            options[:name]  = options[:name].to_s.recode
            options[:value] = options[:value].to_s.recode

            self.inputs = self.class.parse_inputs( options[:value] )
            @data.merge!( options )
        else
            self.inputs = (options[:inputs] || {}).dup
        end

        @data.merge!( DEFAULT.merge( @data ) )
        @data[:value] = decode( @data[:value].to_s ) rescue @data[:value].to_s

        parsed_uri = uri_parse( action )
        if !@data[:path]
            path = parsed_uri.path
            path = !path.empty? ? path : '/'
            @data[:path] = path
        end

        if @data[:expires] && !@data[:expires].is_a?( Time )
            @data[:expires] = Time.parse( @data[:expires].to_s ) rescue nil
        end

        @data[:domain] ||= parsed_uri.host

        @default_inputs = self.inputs.dup.freeze
    end

    # Indicates whether the cookie must be only sent over an encrypted channel.
    #
    # @return   [Bool]
    def secure?
        @data[:secure] == true
    end

    # Indicates whether the cookie is safe from modification from client-side code.
    #
    # @return   [Bool]
    def http_only?
        @data[:httponly] == true
    end

    # Indicates whether the cookie is to be discarded at the end of the session.
    #
    # Doesn't play a role during the scan but it can provide useful info to checks and such.
    #
    # @return   [Bool]
    def session?
        @data[:expires].nil?
    end

    # @return   [Time, NilClass]
    #   Expiration `Time` of the cookie or `nil` if it doesn't have one
    #   (i.e. is a session cookie).
    def expires_at
        @data[:expires]
    end

    # Indicates whether or not the cookie has expired.
    #
    # @param    [Time]    time
    #   To compare against.
    #
    # @return [Boolean]
    def expired?( time = Time.now )
        expires_at != nil && time > expires_at
    end

    # @return   [Hash]
    #   Simple representation of the cookie as a hash -- with the cookie name as
    #   `key` and the cookie value as `value`.
    def simple
        self.inputs.dup
    end

    # Uses the method name as a key to cookie attributes in {DEFAULT}.
    def method_missing( sym, *args, &block )
        return @data[sym] if @data.include? sym
        super( sym, *args, &block )
    end

    # Used by {#method_missing} to determine if it should process the call.
    #
    # @return   [Bool]
    #
    def respond_to?( *args )
        (@data && @data.include?( args.first )) || super
    end

    def value
        self.inputs.map { |n, v| "#{encode( n )}=#{encode( v )}" }.join( '&' )
    end

    # @return   [String]
    #   To be used in a `Cookie` HTTP request header.
    def to_s
        # Only do encoding if we're dealing with updated inputs, otherwise pass
        # along the raw data as set in order to deal with server-side decoding
        # quirks.
        if updated? || !(raw_name || raw_value )
            "#{encode( name )}=#{value}"
        else
            "#{raw_name}=#{raw_value}"
        end
    end

    # @return   [String]
    #   Converts self to a `Set-Cookie` string.
    def to_set_cookie
        set_cookie = "#{self.to_s}"

        @data.each do |k, v|
            next if !v || !Cookie.keep_for_set_cookie.include?( k )

            set_cookie << "; #{k.capitalize}=#{v}"
        end

        set_cookie << '; Secure'   if secure?
        set_cookie << '; HttpOnly' if http_only?

        # If we want to set a cookie for only the domain that responded to the
        # request, Set-Cookie should not specify a domain.
        #
        # If we want the cookie to apply to all subdomains, we need to either
        # specify a dot-prefixed domain or a domain, the browser client will
        # prefix the dot anyways.
        #
        # http://stackoverflow.com/questions/1062963/how-do-browser-cookie-domains-work/1063760#1063760
        set_cookie << "; Domain=#{domain}" if domain.start_with?( '.' )

        set_cookie
    end

    # @see .encode
    def encode( *args )
        self.class.encode( *args )
    end

    # @see .decode
    def decode( str )
        self.class.decode( str )
    end

    def to_rpc_data
        h = super

        if h['initialization_options']['expires']
            h['initialization_options']['expires'] =
                h['initialization_options']['expires'].to_s
        end

        h['data'] = h['data'].my_stringify_keys(false)
        if h['data']['expires']
            h['data']['expires'] = h['data']['expires'].to_s
        end

        h
    end

    class <<self

        def type
            :nested_cookie
        end

        def from_rpc_data( data )
            if data['initialization_options']['expires']
                data['initialization_options']['expires'] =
                    Time.parse( data['initialization_options']['expires'] )
            end

            if data['data']['expires']
                data['data']['expires'] = Time.parse( data['data']['expires'] )
            end

            data['data'] = data['data'].my_symbolize_keys(false)

            super data
        end

        # Parses a Netscape Cookie-jar into an Array of {Cookie}.
        #
        # @param   [String]    url
        #   {HTTP::Request} URL.
        # @param   [String]    filepath
        #   Netscape HTTP cookiejar file.
        #
        # @return   [Array<NestedCookie>]
        #
        # @see http://curl.haxx.se/rfc/cookie_spec.html
        def from_file( url, filepath )
            from_cookies( Cookie.from_file( url, filepath ) )
        end

        # Extracts cookies from an HTTP {Arachni::HTTP::Response response}.
        #
        # @param   [Arachni::HTTP::Response]    response
        #
        # @return   [Array<NestedCookie>]
        #
        # @see .from_parser
        # @see .from_headers
        def from_response( response )
            from_parser( Arachni::Parser.new( response ) ) +
                from_headers( response.url, response.headers )
        end

        # Extracts cookies from a document based on `Set-Cookie` `http-equiv`
        # meta tags.
        #
        # @param    [Arachni::Parser]    parser
        #
        # @return   [Array<NestedCookie>]
        #
        # @see .parse_set_cookie
        def from_parser( parser )
            from_cookies( Cookie.from_parser( parser ) )
        end

        def in_html?( html )
            html =~ /set-cookie.*&/i
        end

        # Extracts cookies from the `Set-Cookie` HTTP response header field.
        #
        # @param    [String]    url
        #   {HTTP::Request} URL.
        # @param    [Hash]      headers
        #
        # @return   [Array<NestedCookie>]
        #
        # @see .forms_set_cookie
        def from_headers( url, headers )
            from_cookies( Cookie.from_headers( url, headers ) )
        end

        # Parses the `Set-Cookie` header value into cookie elements.
        #
        # @param    [String]    url
        #   {HTTP::Request} URL.
        # @param    [Hash]      str
        #   `Set-Cookie` string
        #
        # @return   [Array<NestedCookie>]
        def from_set_cookie( url, str )
            from_cookies( Cookie.from_set_cookie( url, str ) )
        end
        alias :parse_set_cookie :from_set_cookie

        # Parses a string formatted for the `Cookie` HTTP request header field
        # into cookie elements.
        #
        # @param    [String]    url
        #   {HTTP::Request} URL.
        # @param    [Hash]      string
        #   `Cookie` string.
        #
        # @return   [Array<NestedCookie>]
        def from_string( url, string )
            from_cookies( Cookie.from_string( url, string ) )
        end

        def from_cookies( cookies )
            [cookies].flatten.compact.map do |cookie|
                next if !cookie.value.include?( '=' )

                inputs = parse_inputs( cookie.value )
                next if inputs.empty?

                new({
                    url:    cookie.url,
                    action: cookie.action,
                    method: cookie.method,
                    inputs: inputs,
                    source: cookie.source
                }.merge( cookie.data ))
            end.compact
        end

        def parse_inputs( value )
            value.to_s.split( '&' ).inject( {} ) do |h, pair|
                name, value = pair.split( '=', 2 )
                h[decode( name.to_s )] = decode( value.to_s )
                h
            end
        end

        # Encodes a {String}'s reserved characters in order to prepare it for
        # the `Cookie` header field.
        #
        # @param    [String]    str
        #
        # @return   [String]
        def encode( str )
            Cookie.encode( str )
        end

        # Decodes a {String} encoded for the `Cookie` header field.
        #
        # @param    [String]    str
        #
        # @return   [String]
        def decode( str )
            Cookie.decode( str )
        end

    end

    private

    def http_request( opts = {}, &block )
        opts[:cookies] = opts.delete( :parameters )

        self.method == :get ?
            http.get( self.action, opts, &block ) :
            http.post( self.action, opts, &block )
    end

end
end

Arachni::NestedCookie = Arachni::Element::NestedCookie
