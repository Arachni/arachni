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

require 'uri'
require 'addressable/uri'

module Arachni

    # @see Arachni::URI.parse
    def self.URI( uri )
        Arachni::URI.parse( uri )
    end

#
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class URI

    CACHE_SIZES = {
        parse:       600,
        ruby_parse:  600,
        cheap_parse: 600,
        normalize:   1000,
        to_absolute: 1000
    }

    CACHE = {
        parser:      ::URI::Parser.new,
        ruby_parse:  Arachni::Cache::RandomReplacement.new( CACHE_SIZES[:ruby_parse] ),
        parse:       Arachni::Cache::RandomReplacement.new( CACHE_SIZES[:parse] ),
        cheap_parse: Arachni::Cache::RandomReplacement.new( CACHE_SIZES[:cheap_parse] ),
        normalize:   Arachni::Cache::RandomReplacement.new( CACHE_SIZES[:normalize] ),
        to_absolute: Arachni::Cache::RandomReplacement.new( CACHE_SIZES[:to_absolute] )
    }

    # @return [URI::Parser] cached URI parser
    def self.parser
        CACHE[__method__]
    end

    #
    # URL encodes a string.
    #
    # @param [String, #to_str] string   The URI component to encode.
    # @param [String, Regexp] bad_characters    class of characters to encode
    #                                               formatted as a regexp
    #
    # @return   [String]    encoded string
    #
    def self.encode( string, bad_characters = nil )
        Addressable::URI.encode_component( *[string, bad_characters].compact )
    end

    #
    # URL decodes a string.
    #
    # @param [String, #to_str] string   The URI component to encode.
    #
    # @return   [String]    decoded string
    #
    def self.decode( string )
        Addressable::URI.unencode( string )
    end

    #
    # ATTENTION: This method's results are cached for performance reasons.
    # If you plan on doing something destructive with its return value duplicate
    # it first because there may be references to it elsewhere.
    #
    # (will discard the fragment)
    #
    # @param    [String]    url     URL to parse
    #
    # @return   [Arachni::URI]
    #
    def self.parse( url )
        return url if !url || url.is_a?( Arachni::URI )
        CACHE[__method__][url] ||= new( url )
    end

    #
    # Normalizes +url+ and uses Ruby's core URI class to parse it.
    #
    # ATTENTION: This method's results are cached for performance reasons.
    # If you plan on doing something destructive with its return value duplicate
    # it first because there may be references to it elsewhere.
    #
    # (will discard the fragment)
    #
    # @param    [String]    url     URL to parse
    #
    # @return   [URI]
    #
    def self.ruby_parse( url )
        return url if !url || url.is_a?( ::URI )
        CACHE[__method__][url] ||= begin
            ::URI::Generic.build( cheap_parse( url ) )
        rescue
            parser.parse( normalize( url ).dup )
        end
    end

    #
    # Performs a parse that is less resource intensive than Ruby's URI lib's
    # method (will discard the fragment).
    #
    # @param    [String]  url
    #
    # @return   [Hash]  URL components (frozen)
    #
    def self.cheap_parse( url )
        return if !url || url.empty?

        cache = CACHE[__method__]

        url   = url.to_s.dup
        c_url = url.to_s.dup

        components = {
            scheme:   nil,
            userinfo: nil,
            host:     nil,
            port:     nil,
            path:     nil,
            query:    nil
        }

        valid_schemes = %w(http https)

        begin
            if (v = cache[url]) && v == :err
                return
            elsif v
                return v
            end

            url = url.encode( 'UTF-8', undef: :replace, invalid: :replace )
            url = decode( url ) while url =~ /%[a-fA-F0-9]{2}/

            # remove the fragment if there is one
            url = url.split( '#' )[0...-1].join if url.include?( '#' )

            has_path = true

            splits = url.split( ':' )
            if !splits.empty? && valid_schemes.include?( splits.first.downcase )
                splits = url.split( '://', 2 )
                components[:scheme] = splits.shift
                components[:scheme].downcase! if components[:scheme]
                url = splits.shift

                splits = url.split( '@', 2 )

                if splits.size > 1
                    components[:userinfo] = splits.first
                    url = splits.shift
                end

                splits = splits.last.split( '/', 2 )
                has_path = false if !splits[1] || splits[1].empty?

                url = splits.last

                splits = splits.first.split( ':', 2 )
                if splits.size == 2
                    host = splits.first
                    components[:port] = Integer( splits.last )
                    components[:port] = nil if components[:port] == 80
                else
                    host = splits.last
                end

                if components[:host] = host
                    url.gsub!( host, '' )
                    components[:host].downcase!
                end
            end

            if has_path
                splits = url.split( '?', 2 )
                if components[:path] = splits.shift
                    components[:path] = '/' + components[:path] if components[:scheme]
                    components[:path].gsub!( /\/+/, '/' )
                    components[:path] =
                        encode( components[:path], Addressable::URI::CharacterClasses::PATH )
                end

                if components[:query] = splits.shift
                    components[:query] =
                        encode( components[:query], Addressable::URI::CharacterClasses::QUERY )
                end
            end

            components[:path] ||= components[:scheme] ? '/' : nil

            cache[c_url] = components.inject({}) do |h, (k, val)|
                h.merge!( Hash[{ k => val.freeze }] )
            end.freeze
        rescue# => e
            #ap c_url
            #ap url
            #ap e
            #ap e.backtrace
            cache[c_url] = :err
            nil
        end
    end

    #
    # Converts relative URL *link* into an absolute URL based on the
    # location of the page.
    #
    # @param    [String]    relative_url
    # @param    [String]    reference_url    absolute url to use as a reference
    #
    # @return   [String]  absolute URL (frozen)
    #
    def self.to_absolute( relative, reference = Arachni::Options.instance.url.to_s )
        return reference if !relative || relative.empty?
        key = relative + ' :: ' + reference

        cache = CACHE[__method__]
        begin
            if (v = cache[key]) && v == :err
                return
            elsif v
                return v
            end

            cache[key] = parse( relative ).to_absolute( reference ).to_s
        rescue# => e
              #ap relative
              #ap e
              #ap e.backtrace
            cache[key] = :err
            nil
        end
    end

    #
    # Encodes and converts URLs to a common format.
    #
    # @param    [String]    url
    #
    # @return   [String]    normalized URL (frozen)
    #
    def self.normalize( url )
        return if !url || url.empty?

        cache = CACHE[__method__]

        url   = url.to_s.dup
        c_url = url.to_s.dup

        begin
            if (v = cache[url]) && v == :err
                return
            elsif v
                return v
            end

            components = cheap_parse( url )

            #ap components
            normalized = ''
            normalized << components[:scheme] + '://' if components[:scheme]

            if components[:userinfo]
                normalized << components[:userinfo]
                normalized << '@'
            end

            if components[:host]
                normalized << components[:host]
                normalized << ':' + components[:port].to_s if components[:port]
            end

            normalized << components[:path] if components[:path]
            normalized << '?' + components[:query] if components[:query]

            cache[c_url] = normalized.freeze

            #addr = Addressable::URI.parse( c_url ).normalize
            #addr.fragment = nil
            #addr.path.gsub!( /\/+/, '/' )
            #if addr.to_s != normalized
            #    ap c_url
            #    ap components
            #    ap normalized
            #    ap addr.to_s
            #    ap '~~~'
            #end
            #@@normalize_cache[c_url]
        rescue# => e
            #ap c_url
            #ap url
            #ap e
            #ap e.backtrace
            cache[c_url] = :err
            nil
        end
    end

    #
    # @param    [String, URI, Hash]    url
    #   String URL to parse, URI to convert, or a Hash holding URL components
    #   for ::URI::Generic.build.
    #
    def initialize( url )
        @arachni_opts = Arachni::Options.instance
        #@parsed_url   = self.class.parser.parse( self.class.normalize( url ) )

        @parsed_url = case url
            when String
                self.class.ruby_parse( url )

            when ::URI
                url.dup

            when Hash
                ::URI::Generic.build( url )

            when Arachni::URI
                self.parsed_url = url.parsed_url.dup

            else
                fail TypeError.new( 'Argument must either be String, URI or Hash.' )
            end
    end

    def ==( other )
        to_s == other.to_s
    end

    #
    # Converts self into an absolute URL based using +reference+.
    #
    # @param    [Arachni::URI, URI, String]    reference    absolute url to use as a reference
    #
    # @return   [Arachni::URI]  self as an absolute URL
    #
    def to_absolute( reference )
        absolute = case reference
             when Arachni::URI
                 reference.parsed_url
            when ::URI
                reference
            else
                self.class.new( reference.to_s ).parsed_url
           end.merge( @parsed_url )

        self.class.new( absolute )
    end

    # @return   [String]    the URL up to its path component
    #                           (no resource name, query, fragment, etc)
    def up_to_path
        uri_path = path.dup

        uri_path = File.dirname( uri_path ) if !File.extname( path ).empty?

        uri_path << '/' if uri_path[-1] != '/'

        uri_str = scheme + "://" + host
        uri_str << ':' + port.to_s if port && port != 80
        uri_str << uri_path
    end

    # @return [String]  domain_name.tld
    def domain
        s = host.split( '.' )
        return s.first if s.size == 1
        return host if s.size == 2

        s[1..-1].join( '.' )
    end

    #
    # Checks if self exceeds a given directory depth.
    #
    # @param    [Integer]   depth   depth to check for
    #
    # @return   [Bool]  +true+ if self is deeper than +depth+, +false+ otherwise
    #
    def too_deep?( depth )
        depth > 0 && (depth + 1) <= path.count( '/' )
    end

    #
    # Checks if self should be excluded based on the provided +patterns+.
    #
    # @param    [Array<Regexp,String>] patterns
    #
    # @return   [Bool]  +true+ if self matches a pattern, +false+ otherwise
    #
    def exclude?( patterns )
        fail TypeError.new( 'Array<Regexp,String> expected, got nil instead' ) if patterns.nil?
        ensure_patterns( patterns ).each { |pattern| return true if to_s =~ pattern }
        false
    end

    #
    # Checks if self should be included based on the provided +patterns+.
    #
    # @param    [Array<Regexp,String>] patterns
    #
    # @return   [Bool]  +true+ if self matches a pattern (or +patterns+ are +nil+ or empty),
    #                       +false+ otherwise
    #
    def include?( patterns )
        fail TypeError.new( 'Array<Regexp,String> expected, got nil instead' ) if patterns.nil?

        rules = ensure_patterns( patterns )
        return true if !rules || rules.empty?

        rules.each { |pattern| return true if to_s =~ pattern }
        false
    end

    #
    # @param    [Bool]  include_subdomain Match subdomains too?
    #   If true will compare full hostnames, otherwise will discard subdomains.
    #
    # @param    [Arachni::URI, URI, Hash, String]    url to compare it to
    #
    # @return   [Bool]  +true+ if self is in the same domain as the +other+ URL,
    #                       false otherwise
    #
    def in_domain?( include_subdomain, other )
        return true if !other

        other = self.class.new( other ) if !other.is_a?( Arachni::URI )
        include_subdomain ? other.host == host : other.domain == domain
    end

    def to_s
        @parsed_url.to_s
    end

    protected

    def parsed_url
        @parsed_url
    end

    def parsed_url=( url )
        @parsed_url = url
    end

    private

    def ensure_patterns( arr )
        if arr.is_a?( Array )
            arr
        else
            [arr].flatten
        end.compact.map { |p| p.is_a?( Regexp ) ? p : Regexp.new( p.to_s ) }
    end

    def method_missing( sym, *args, &block )
        if @parsed_url.respond_to?( sym )
            @parsed_url.send( sym, *args, &block )
        else
            super
        end
    end

    def respond_to?( sym )
        super || @parsed_url.respond_to?( sym )
    end

end
end
