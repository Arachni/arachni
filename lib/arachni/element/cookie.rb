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

require 'webrick'
require 'uri'

require Arachni::Options.dir['lib'] + 'element/base'

module Arachni::Element

COOKIE = 'cookie'

#
# Represents a Cookie object and provides helper class methods for parsing, encoding, etc.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Cookie < Arachni::Element::Base

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
    #   For options see {#DEFAULT}, with the following extras:
    # @option   options [String]    :url
    #   URL of the page which created the cookie -- **required**.
    # @option   options [String]     :action
    #   URL of the page to submit the cookie -- defaults to `:url`.
    # @option   options [Hash]     :inputs
    #   Allows you to pass cookie data as a `name => value` pair instead of the
    #   more complex {#DEFAULT} structure.
    def initialize( options )
        @data = {}
        super( options )

        self.method = :get

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

        @data[:domain] ||= parsed_uri.host

        @original = self.inputs.dup.freeze
    end

    #
    # Overrides {Capabilities::Auditable#audit} to enforce cookie exclusion
    # settings from {Arachni::Options#exclude_cookies}.
    #
    # @see Capabilities::Auditable#audit
    #
    def audit( *args )
        if Arachni::Options.exclude_cookies.include?( name )
            auditor.print_info "Skipping audit of '#{name}' cookie."
            return
        end
        super( *args )
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
    # Doesn't play a role during the scan but it can provide useful info to modules and such.
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
    # @param    [Time]    time    To compare against.
    #
    # @return [Boolean]
    def expired?( time = Time.now )
        expires_at != nil && time > expires_at
    end

    #
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

    # @return   [String]    Name of the current element, 'cookie' in this case.
    # @see Arachni::Element::COOKIE
    def type
        Arachni::Element::COOKIE
    end

    def dup
        super.tap { |d| d.action = self.action }
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
    #
    # @param    [Hash]  inputs   Sets inputs.
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

    # Overrides {Capabilities::Mutable#mutations} to handle cookie-specific
    # limitations and the {Arachni::Options#audit_cookies_extensively} option.
    #
    # @see Capabilities::Mutable#mutations
    def mutations( injection_str, opts = {} )
        flip = opts.delete( :param_flip )
        muts = super( injection_str, opts )

        if flip
            elem = self.dup

            # when under HPG mode element auditing is strictly regulated
            # and when we flip params we essentially create a new element
            # which won't be on the whitelist
            elem.override_instance_scope

            elem.altered = 'Parameter flip'
            elem.inputs = { injection_str => seed }
            muts << elem
        end

        if !orphan? && Arachni::Options.audit_cookies_extensively?
            # submit all links and forms of the page along with our cookie mutations
            muts << muts.map do |m|
                (auditor.page.links | auditor.page.forms).map do |e|
                    next if e.inputs.empty?
                    c = e.dup
                    c.altered = "mutation for the '#{m.altered}' cookie"
                    c.auditor = auditor
                    c.audit_options[:cookies] = m.inputs.dup
                    c.inputs = Arachni::Module::KeyFiller.fill( c.inputs.dup )
                    c
                end
            end.flatten.compact
            muts.flatten!
        end

        muts
    end

    # Uses the method name as a key to cookie attributes in {DEFAULT}.
    def method_missing( sym, *args, &block )
        return @data[sym] if respond_to?( sym )
        super( sym, *args, &block )
    end

    #
    # Used by {#method_missing} to determine if it should process the call.
    #
    # @return   [Bool]
    #
    def respond_to?( sym )
        (@data && @data.include?( sym )) || super( sym )
    end

    # @return   [String]    To be used in a `Cookie` HTTP request header.
    def to_s
        "#{encode( name )}=#{encode( value )}"
    end

    # Parses a Netscape Cookie-jar into an Array of {Cookie}.
    #
    # @param   [String]    url          request URL
    # @param   [String]    filepath     Netscape HTTP cookiejar file
    #
    # @return   [Array<Cookie>]
    #
    # @see http://curl.haxx.se/rfc/cookie_spec.html
    def self.from_file( url, filepath )
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
    def self.expires_to_time( expires )
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
    def self.from_response( response )
        ( from_document( response.url, response.body ) |
         from_headers( response.url, response.headers ) )
    end

    # Extracts cookies from a document based on `Set-Cookie` `http-equiv` meta tags.
    #
    # @param    [String]    url     Owner URL.
    # @param    [String, Nokogiri::HTML::Document]    document
    #
    # @return   [Array<Cookie>]
    #
    # @see .parse_set_cookie
    def self.from_document( url, document )
        # optimizations in case there are no cookies in the doc,
        # avoid parsing unless absolutely necessary!
        if !document.is_a?( Nokogiri::HTML::Document )
            # get get the head in order to check if it has an http-equiv for set-cookie
            head = document.to_s.match( /<head(.*)<\/head>/imx )

            # if it does feed the head to the parser in order to extract the cookies
            return [] if !head || !head.to_s.downcase.substring?( 'set-cookie' )

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
    # @param    [String]    url     request URL
    # @param    [Hash]      headers
    #
    # @return   [Array<Cookie>]
    #
    # @see .forms_set_cookie
    def self.from_headers( url, headers )
        headers = Arachni::HTTP::Headers.new( headers )
        return [] if headers.set_cookie.empty?

        exception_jail {
            headers.set_cookie.map { |c| from_set_cookie( url, c ) }.flatten
        } rescue []
    end

    # Parses the `Set-Cookie` header value into cookie elements.
    #
    #
    # @param    [String]    url     Request URL.
    # @param    [Hash]      str     `Set-Cookie` string
    #
    # @return   [Array<Cookie>]
    def self.from_set_cookie( url, str )
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
    def self.parse_set_cookie( *args )
        from_set_cookie( *args )
    end

    # Parses a string formatted for the `Cookie` HTTP request header field
    # into cookie elements.
    #
    # @param    [String]    url     Request URL.
    # @param    [Hash]      string  `Set-Cookie` string.
    #
    # @return   [Array<Cookie>]
    def self.from_string( url, string )
        return [] if string.empty?
        string.split( ';' ).map do |cookie_pair|
            k, v = *cookie_pair.split( '=', 2 )
            new( url: url, inputs: { decode( k.strip ) => decode( v.strip ) } )
        end.flatten.compact
    end

    #
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
    #
    def self.encode( str )
        URI.encode( str, "+;%=\0" ).recode.gsub( ' ', '+' )
    end
    # @see .encode
    def encode( str )
        self.class.encode( str )
    end

    #
    # Decodes a {String} encoded for the `Cookie` header field.
    #
    # @example
    #    p Cookie.decode "%2B%3B%25%3D%00+"
    #    #=> "+;%=\x00 "
    #
    # @param    [String]    str
    #
    # @return   [String]
    #
    def self.decode( str )
        URI.decode( str.to_s.recode.gsub( '+', ' ' ) )
    end
    # @see .decode
    def decode( str )
        self.class.decode( str )
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
