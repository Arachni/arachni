=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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

opts = Arachni::Options.instance
require opts.dir['lib'] + 'parser/element/base'

class Arachni::Parser::Element::Cookie < Arachni::Parser::Element::Base

    #
    # Default cookie values
    #
    DEFAULT = {
           "name" => nil,
          "value" => nil,
        "version" => 0,
           "port" => nil,
        "discard" => nil,
    "comment_url" => nil,
        "expires" => nil,
        "max_age" => nil,
        "comment" => nil,
         "secure" => nil,
           "path" => nil,
         "domain" => nil,
       "httponly" => false
    }

    def initialize( url, raw = {} )
        super( url, raw )

        @action = @url
        @method = 'cookie'

        if @raw['name'] && @raw['value']
            @auditable = { @raw['name'] => @raw['value'] }
        else
            @auditable = raw.dup
            @raw = {
                'name'  => @auditable.keys.first,
                'value' => @auditable.values.first
            }
        end

        @raw.merge!( DEFAULT.merge( @raw ) )
        if @raw['value'] && !@raw['value'].empty?
            @raw['value'] = uri_decode( @raw['value'].gsub( '+', ' ' ) )
        end

        parsed_uri = uri_parse( @url )
        if !@raw['path']
            path = parsed_uri.path
            path = !path.empty? ? path : '/'
            @raw['path'] = path
        end

        @raw['domain'] ||= parsed_uri.host

        @raw['max_age'] = @raw['max_age'] if @raw['max_age']

        @simple = @auditable.dup
        @orig = @auditable.deep_clone
        @orig.freeze
    end

    def audit( *args )
        if Arachni::Options.instance.exclude_cookies.include?( name )
            auditor.print_info "Skipping audit of '#{name}' cookie."
            return
        end
        super( *args )
    end

    #
    # Indicates whether the cookie must be only sent over an encrypted channel.
    #
    # @return   [Bool]
    #
    def secure?
        @raw['secure'] == true
    end

    #
    # Indicates whether the cookie is safe from modification from client-side code.
    #
    # @return   [Bool]
    #
    def http_only?
        @raw['httponly'] == true
    end

    #
    # Indicates whether the cookie is to be discarded at the end of the session.
    #
    # Doesn't play a role during the scan but it can provide useful info to modules and such.
    #
    # @return   [Bool]
    #
    def session?
        @raw['expires'].nil?
    end

    #
    # @return   [Time, NilClass]    expiration time of the cookie or nil if it
    #                               doesn't have one (i.e. is a session cookie)
    #
    def expires_at
        expires
    end
    #
    # Indicates whether the cookie has expired.
    #
    # @param    [Time]    time    to compare against
    #
    # @return [Boolean]
    #
    def expired?( time = Time.now )
        expires_at != nil && time > expires_at
    end

    #
    # @return   [Hash]    simple representation of the cookie as a hash with the
    #                     value as key and the cookie value as value.
    def simple
        @simple
    end

    #
    # @return   [String]    name of the current element, 'cookie' in this case.
    #
    def type
        Arachni::Module::Auditor::Element::COOKIE
    end

    #
    # Uses the method name as a key to cookie attributes in {DEFAULT}.
    #
    # Like:
    #    cookie.name
    #    cookie.domain
    #
    def method_missing( sym, *args, &block )
        return @raw[sym.to_s] if respond_to?( sym )
        super( sym, *args, &block )
    end

    #
    # Used by {#method_missing} to determine if it should process the call.
    #
    # @return   [Bool]
    #
    def respond_to?( sym )
        @raw.include?( sym.to_s ) || super( sym )
    end

    #
    # @return   [String]    to be used in a 'Cookie' request header. (name=value)
    #
    def to_s
        "#{name}=#{uri_encode( uri_encode( value ), '+;' )}"
    end

    #
    # Returns an array of cookies from an Netscape HTTP cookiejar file.
    #
    # @param   [String]    url          request URL
    # @param   [String]    filepath     Netscape HTTP cookiejar file
    #
    # @return   [Array<Cookie>]
    #
    def self.from_file( url, filepath )
        File.open( filepath, 'r' ).map {
            |line|
            # skip empty lines
            next if (line = line.strip).empty? || line[0] == '#'

            c = {}
            c['domain'], foo, c['path'], c['secure'], c['expires'], c['name'],
                c['value'] = *line.split( "\t" )

            # expiry date is optional so if we don't have one push everything back
            begin
                c['expires'] = Time.parse( c['expires'] )
            rescue
                c['value'] = c['name'].dup
                c['name'] = c['expires'].dup
                c['expires'] = nil
            end
            c['secure'] = (c['secure'] == 'TRUE') ? true : false
            new( url, c )
        }.flatten.compact
    end

    #
    # Returns an array of cookies based on HTTP response.
    #
    # @param   [Typhoeus::Response]    response
    #
    # @return   [Array<Cookie>]
    #
    # @see from_document
    # @see from_headers
    #
    def self.from_response( response )
        ( from_document( response.effective_url, response.body ) |
         from_headers( response.effective_url, response.headers_hash ) )
    end

    #
    # Returns an array of cookies from a document based on 'Set-Cookie' http-equiv meta tags.
    #
    # @param    [String]    url     request URL
    # @param    [String, Nokogiri::HTML::Document]    document
    #
    # @return   [Array<Cookie>]
    #
    # @see parse_set_cookies
    #
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

        Arachni::Module::Utilities.exception_jail{
            document.search( "//meta[@http-equiv]" ).map {
                |elem|
                next if elem['http-equiv'].downcase != 'set-cookie'
                parse_set_cookies( url, elem['content'] )
            }.flatten.compact
        } rescue []
    end

    #
    # Returns an array of cookies from a the 'Set-Cookie' header field.
    #
    # @param    [String]    url     request URL
    # @param    [Hash]      headers
    #
    # @return   [Array<Cookie>]
    #
    # @see parse_set_cookies
    #
    def self.from_headers( url, headers )
        set_strings = []
        headers.each {
            |k, v|
            set_strings = [v].flatten if k.downcase == 'set-cookie'
        }

        return set_strings if set_strings.empty?
        Arachni::Module::Utilities.exception_jail{
            set_strings.map { |c| parse_set_cookies( url, c ) }.flatten
        } rescue []
    end

    #
    # Parses a 'set-cookie' string into cookie elements.
    #
    # @param    [String]    url     request URL
    # @param    [Hash]      str     set-cookie string
    #
    # @return   [Array<Cookie>]
    #
    def self.parse_set_cookies( url, str )
        WEBrick::Cookie.parse_set_cookies( str ).flatten.uniq.map {
            |cookie|
            cookie_hash = {}
            cookie.instance_variables.each {
                |var|
                cookie_hash[var.to_s.gsub( /@/, '' )] = cookie.instance_variable_get( var )
            }
            cookie_hash['expires'] = cookie.expires
            new( url.to_s, cookie_hash )
        }.flatten.compact
    end

    private
    def http_request( opts = {} )
        http.cookie( @action, opts || {} )
    end

end
