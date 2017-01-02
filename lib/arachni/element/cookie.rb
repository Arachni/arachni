=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'webrick'
require 'uri'

require_relative 'base'

module Arachni::Element

# Represents a Cookie object and provides helper class methods for parsing,
# encoding, etc.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Cookie < Base
    require_relative 'cookie/dom'

    # Load and include all cookie-specific capability overrides.
    lib = "#{File.dirname( __FILE__ )}/#{File.basename(__FILE__, '.rb')}/capabilities/**/*.rb"
    Dir.glob( lib ).each { |f| require f }

    # Generic element capabilities.
    include Arachni::Element::Capabilities::Submittable
    include Arachni::Element::Capabilities::Auditable
    include Arachni::Element::Capabilities::Auditable::Buffered
    include Arachni::Element::Capabilities::Auditable::LineBuffered
    include Arachni::Element::Capabilities::Analyzable
    include Arachni::Element::Capabilities::WithSource

    # Cookie-specific overrides.
    include Capabilities::WithDOM
    include Capabilities::Inputtable
    include Capabilities::Mutable

    ENCODE_CHARACTERS      = ['+', ';', '%', "\0", '&', ' ', '"', "\n", "\r", '=']
    ENCODE_CHARACTERS_LIST = ENCODE_CHARACTERS.join

    ENCODE_CACHE = Arachni::Support::Cache::LeastRecentlyPushed.new( 1_000 )

    # Default cookie values
    DEFAULT = {
        name:        nil,
        value:       nil,
        raw_name:    nil,
        raw_value:   nil,
        version:     0,
        port:        nil,
        discard:     nil,
        comment_url: nil,
        expires:     nil,
        max_age:     nil,
        comment:     nil,
        secure:      nil,
        path:        nil,
        domain:      nil,
        httponly:    false
    }

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

            self.inputs = { options[:name] => options[:value] }
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

    # @example
    #    p Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff' ).first.simple
    #    #=> {"session"=>"stuffstuffstuff"}
    #
    #
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

    # @return   [String]
    #   To be used in a `Cookie` HTTP request header.
    def to_s
        # Only do encoding if we're dealing with updated inputs, otherwise pass
        # along the raw data as set in order to deal with server-side decoding
        # quirks.
        if updated? || !(raw_name || raw_value )
            "#{encode( name )}=#{encode( value )}"
        else
            "#{raw_name}=#{raw_value}"
        end
    end

    # @return   [String]
    #   Converts self to a `Set-Cookie` string.
    def to_set_cookie
        set_cookie = "#{self.to_s}"

        @data.each do |k, v|
            next if !v || !self.class.keep_for_set_cookie.include?( k )

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
        # @return   [Array<Cookie>]
        #
        # @see http://curl.haxx.se/rfc/cookie_spec.html
        def from_file( url, filepath )
            File.open( filepath, 'r' ).map do |line|
                # skip empty lines
                next if (line = line.strip).empty? || line[0] == '#'

                c = {}
                c['domain'], _, c['path'], c['secure'], c['expires'], c['name'],
                    c['value'] = *line.split( "\t" )

                # expiry date is optional so if we don't have one push everything back
                begin
                    c['expires'] = expires_to_time( c['expires'] )
                rescue
                    c['value'] = c['name'].dup
                    c['name'] = c['expires'].dup
                    c['expires'] = nil
                end

                c['secure'] = (c['secure'] == 'TRUE') ? true : false

                c['raw_name'] = c['name']
                c['name'] = decode( c['name'] )

                c['raw_value'] = c['value']
                c['value'] = decode( c['value'] )

                new( { url: url }.merge( c.my_symbolize_keys ) )
            end.flatten.compact
        end

        # Converts a cookie's expiration date to a Ruby `Time` object.
        #
        # @example String time format
        #    p Cookie.expires_to_time "Tue, 02 Oct 2012 19:25:57 GMT"
        #    #=> 2012-10-02 22:25:57 +0300
        #
        # @example Seconds since Epoch
        #    p Cookie.expires_to_time "1596981560"
        #    #=> 2020-08-09 16:59:20 +0300
        #
        #    p Cookie.expires_to_time 1596981560
        #    #=> 2020-08-09 16:59:20 +0300
        #
        # @param    [String]    expires
        #
        # @return   [Time]
        def expires_to_time( expires )
            return nil if expires == '0'
            (expires_to_i = expires.to_i) > 0 ? Time.at( expires_to_i ) : Time.parse( expires )
        end

        # Extracts cookies from an HTTP {Arachni::HTTP::Response response}.
        #
        # @param   [Arachni::HTTP::Response]    response
        #
        # @return   [Array<Cookie>]
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
        # @return   [Array<Cookie>]
        #
        # @see .parse_set_cookie
        def from_parser( parser )
            return [] if parser.body && !in_html?( parser.body )

            Arachni::Utilities.exception_jail {
                parser.document.nodes_by_name( :meta ).map do |elem|
                    next if elem['http-equiv'].downcase != 'set-cookie'

                    from_set_cookie( parser.url, elem['content'] )
                end.flatten.compact
            } rescue []
        end

        def in_html?( html )
            html =~ /set-cookie/i
        end

        # Extracts cookies from the `Set-Cookie` HTTP response header field.
        #
        # @param    [String]    url
        #   {HTTP::Request} URL.
        # @param    [Hash]      headers
        #
        # @return   [Array<Cookie>]
        #
        # @see .forms_set_cookie
        def from_headers( url, headers )
            headers = Arachni::HTTP::Headers.new( headers )
            return [] if headers.set_cookie.empty?

            exception_jail {
                headers.set_cookie.map { |c| from_set_cookie( url, c ) }.flatten
            } rescue []
        end

        # Parses the `Set-Cookie` header value into cookie elements.
        #
        # @param    [String]    url
        #   {HTTP::Request} URL.
        # @param    [Hash]      str
        #   `Set-Cookie` string
        #
        # @return   [Array<Cookie>]
        def from_set_cookie( url, str )
            WEBrick::Cookie.parse_set_cookies( str ).flatten.uniq.map do |cookie|
                cookie_hash = {}
                cookie.instance_variables.each do |var|
                    cookie_hash[var.to_s.gsub( /@/, '' )] = cookie.instance_variable_get( var )
                end

                # http://stackoverflow.com/questions/1062963/how-do-browser-cookie-domains-work/1063760#1063760
                if cookie_hash['domain']
                    # IP addresses must be used verbatim.
                    if !Arachni::URI( "http://#{cookie_hash['domain']}/" ).ip_address?
                        cookie_hash['domain'] =
                            ".#{cookie_hash['domain'].sub( /^\./, '' )}"
                    end
                end

                cookie_hash['expires'] = cookie.expires

                cookie_hash['path'] ||= '/'
                cookie_hash['raw_name']  = cookie.name
                cookie_hash['name']  = decode( cookie.name )

                if too_big?( cookie.value )
                    cookie_hash['value'] = ''
                else
                    quoted = "\"#{cookie.value}\""
                    if str.include? quoted
                        cookie_hash['raw_value']  = quoted
                    else
                        cookie_hash['raw_value']  = cookie.value
                    end

                    cookie_hash['value'] = decode( cookie.value )
                end

                new( { url: url, source: str }.merge( cookie_hash.my_symbolize_keys ) )
            end.flatten.compact
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
        # @return   [Array<Cookie>]
        def from_string( url, string )
            return [] if string.empty?

            string.split( ';' ).map do |cookie_pair|
                cookie_pair.strip!

                k, v = *cookie_pair.split( '=', 2 )

                v = '' if too_big?( v )

                new(
                    url:       url,
                    source:    cookie_pair,
                    raw_name:  k,
                    raw_value: v,
                    name:      decode( k ),
                    value:     value_to_v0( v )
                )
            end.flatten.compact
        end

        def value_to_v0( value )
            return '' if !value

            value.start_with?( '"' ) && value.end_with?( '"' ) ?
                value[1...-1] : decode( value )
        end

        # Encodes a {String}'s reserved characters in order to prepare it for
        # the `Cookie` header field.
        #
        # @example
        #    p Cookie.encode "+;%=\0 "
        #    #=> "%2B%3B%25%3D%00+"
        # @param    [String]    str
        #
        # @return   [String]
        def encode( str )
            str = str.to_s

            ENCODE_CACHE.fetch( [str, name] )  do
                if ENCODE_CHARACTERS.find { |c| str.include? c }

                    # Instead of just encoding everything we do this selectively because:
                    #
                    #  * Some webapps don't actually decode some cookies, they just get
                    #    the raw value, so if we encode something may break.
                    #  * We need to encode spaces as '+' because of the above.
                    #    Since we decode values, any un-encoded '+' will be converted
                    #    to spaces, and in order to send back a value that the server
                    #    expects we use '+' for spaces.

                    s = ::URI.encode( str, ENCODE_CHARACTERS_LIST )
                    s.gsub!( '%20', '+' )
                    s
                else
                    str
                end
            end
        end

        # Decodes a {String} encoded for the `Cookie` header field.
        #
        # @example
        #    p Cookie.decode "%2B%3B%25%3D%00+"
        #    #=> "+;%=\x00 "
        #
        # @param    [String]    str
        #
        # @return   [String]
        def decode( str )
            Form.decode str
        end

        def keep_for_set_cookie
            return @keep if @keep

            @keep = Set.new( DEFAULT.keys )
            @keep.delete( :name )
            @keep.delete( :value )
            @keep.delete( :raw_name )
            @keep.delete( :raw_value )
            @keep.delete( :domain )
            @keep.delete( :url )
            @keep.delete( :secure )
            @keep.delete( :httponly )
            @keep.delete( :version )
            @keep
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

Arachni::Cookie = Arachni::Element::Cookie
