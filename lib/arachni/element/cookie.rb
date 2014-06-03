=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'webrick'
require 'uri'

require_relative 'base'

module Arachni::Element

# Represents a Cookie object and provides helper class methods for parsing,
# encoding, etc.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Cookie < Base
    require_relative 'cookie/dom'

    include Capabilities::WithDOM
    include Capabilities::Analyzable

    # Default cookie values
    DEFAULT = {
        name:        nil,
        value:       nil,
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
        @data[:value] = decode( @data[:value].to_s )

        parsed_uri = uri_parse( action )
        if !@data[:path]
            path = parsed_uri.path
            path = !path.empty? ? path : '/'
            @data[:path] = path
        end

        @data[:domain] ||= ".#{parsed_uri.host}"

        @default_inputs = self.inputs.dup.freeze
    end

    # @return   [DOM]
    def dom
        return if @skip_dom || inputs.empty?

        # In case the cookie already has input data not supported by its DOM
        # extension.
        @skip_dom = !try_input { super }

        @dom
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
        expires
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

    # @example
    #    p c = Cookie.from_set_cookie( 'http://owner-url.com', 'session=stuffstuffstuff' ).first
    #    #=> ["session=stuffstuffstuff"]
    #
    #    p c.inputs
    #    #=> {"session"=>"stuffstuffstuff"}
    #
    #    p c.inputs = { 'new-name' => 'new-value' }
    #    #=> {"new-name"=>"new-value"}
    #
    #    p c
    #    #=> new-name=new-value
    #
    # @param    [Hash]  inputs
    #   Sets inputs.
    def inputs=( inputs )
        k = inputs.keys.first.to_s
        v = inputs.values.first.to_s

        @data[:name]  = k
        @data[:value] = v

        if k.to_s.empty?
            super( {} )
        else
            super( { k => v } )
        end
    end

    # Overrides {Capabilities::Mutable#each_mutation} to handle cookie-specific
    # limitations and the {Arachni::Options#audit_cookies_extensively} option.
    #
    # @param (see Capabilities::Mutable#each_mutation)
    # @return (see Capabilities::Mutable#each_mutation)
    # @yield (see Capabilities::Mutable#each_mutation)
    # @yieldparam (see Capabilities::Mutable#each_mutation)
    #
    # @see Capabilities::Mutable#each_mutation
    def each_mutation( payload, opts = {}, &block )
        flip = opts.delete( :param_flip )

        super( payload, opts ) do |elem|
            yield elem

            next if !Arachni::Options.audit.cookies_extensively?
            elem.each_extensive_mutation( elem, &block )
        end

        return if !flip

        if !valid_input_name_data?( payload )
            print_debug_level_2 'Payload not supported as input value by' <<
                                    " #{audit_id}: #{payload.inspect}"
            return
        end

        elem = self.dup
        elem.affected_input_name = 'Parameter flip'
        elem.inputs = { payload => seed }
        yield elem if block_given?
    end

    def each_extensive_mutation( mutation )
        return if orphan?

        (auditor.page.links | auditor.page.forms).each do |e|
            next if e.inputs.empty?

            c = e.dup
            c.affected_input_name = "mutation for the '#{name}' cookie"
            c.auditor = auditor
            c.audit_options[:submit] ||= {}
            c.audit_options[:submit][:cookies] = mutation.inputs.dup
            c.inputs = Arachni::Options.input.fill( c.inputs.dup )

            yield c
        end
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
        "#{encode( name, :name )}=#{encode( value )}"
    end

    # @return   [String]
    #   Converts self to a `Set-Cookie` string.
    def to_set_cookie
        set_cookie = "#{self.to_s}; "
        set_cookie << @data.map do |k, v|
            next if !v || !self.class.keep_for_set_cookie.include?( k )
            "#{k.capitalize}=#{v}"
        end.compact.join( '; ' )

        set_cookie << '; Secure'   if secure?
        set_cookie << '; HttpOnly' if http_only?
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

    class <<self

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
                c['domain'], foo, c['path'], c['secure'], c['expires'], c['name'],
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
                new( { url: url }.merge( c.symbolize_keys ) )
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
        # @see .from_document
        # @see .from_headers
        def from_response( response )
            ( from_document( response.url, response.body ) |
                from_headers( response.url, response.headers ) )
        end

        # Extracts cookies from a document based on `Set-Cookie` `http-equiv`
        # meta tags.
        #
        # @param    [String]    url
        #   Owner URL.
        # @param    [String, Nokogiri::HTML::Document]    document
        #
        # @return   [Array<Cookie>]
        #
        # @see .parse_set_cookie
        def from_document( url, document )
            # optimizations in case there are no cookies in the doc,
            # avoid parsing unless absolutely necessary!
            if !document.is_a?( Nokogiri::HTML::Document )
                # get get the head in order to check if it has an http-equiv for set-cookie
                head = document.to_s.match( /<head(.*)<\/head>/imx )

                # if it does feed the head to the parser in order to extract the cookies
                return [] if !head || !head.to_s.downcase.include?( 'set-cookie' )

                document = Nokogiri::HTML( head.to_s )
            end

            Arachni::Utilities.exception_jail {
                document.search( "//meta[@http-equiv]" ).map do |elem|
                    next if elem['http-equiv'].downcase != 'set-cookie'
                    from_set_cookie( url, elem['content'] )
                end.flatten.compact
            } rescue []
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
                cookie_hash['expires'] = cookie.expires

                cookie_hash['path'] ||= '/'
                cookie_hash['name']  = decode( cookie.name )
                cookie_hash['value'] = decode( cookie.value )

                new( { url: url }.merge( cookie_hash.symbolize_keys ) )
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
                k, v = *cookie_pair.split( '=', 2 )
                new( url: url, inputs: { decode( k.strip ) => decode( v.strip ) } )
            end.flatten.compact
        end

        # Encodes a {String}'s reserved characters in order to prepare it for
        # the `Cookie` header field.
        #
        # @example
        #    p Cookie.encode "+;%=\0 "
        #    #=> "%2B%3B%25%3D%00+"
        #
        # @param    [String]    str
        #
        # @return   [String]
        def encode( str, type = :value )
            reserved = "+;%\0"
            reserved << '=' if type == :name

            URI.encode( str, reserved ).recode.gsub( ' ', '+' )
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
            URI.decode( str.to_s.recode.gsub( '+', ' ' ) )
        end

        def keep_for_set_cookie
            return @keep if @keep

            @keep = Set.new( DEFAULT.keys )
            @keep.delete( :name )
            @keep.delete( :value )
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
