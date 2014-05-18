=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'uri'
require 'ipaddr'
require 'addressable/uri'

module Arachni

    #
    # Helper method which parses a URL using {Arachni::URI.parse}.
    #
    # @see Arachni::URI.parse
    #
    def self.URI( uri )
        Arachni::URI.parse( uri )
    end

#
# The URI class automatically normalizes the URLs it is passed to parse
# while maintaining compatibility with Ruby's URI core class by delegating
# missing methods to it -- thus, you can treat it like a Ruby URI and enjoy some
# extra perks along the line.
#
# It also provides *cached* (to maintain a low latency) helper class methods to
# ease common operations such as:
#
# * {.normalize Normalization}.
# * Parsing to {.parse Arachni::URI} (see also {.URI}), {.ruby_parse ::URI} or
#   {.cheap_parse Hash} objects.
# * Conversion to {.to_absolute absolute URLs}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class URI
    include UI::Output
    extend  UI::Output

    include Utilities
    extend  Utilities

    #
    # {URI} error namespace.
    #
    # All {URI} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    #
    class Error < Arachni::Error
    end

    CACHE_SIZES = {
        parse:       600,
        ruby_parse:  600,
        cheap_parse: 600,
        normalize:   1000,
        to_absolute: 1000
    }

    CACHE = {
        parser:      ::URI::Parser.new,
        ruby_parse:  Support::Cache::RandomReplacement.new( CACHE_SIZES[:ruby_parse] ),
        parse:       Support::Cache::RandomReplacement.new( CACHE_SIZES[:parse] ),
        cheap_parse: Support::Cache::RandomReplacement.new( CACHE_SIZES[:cheap_parse] ),
        normalize:   Support::Cache::RandomReplacement.new( CACHE_SIZES[:normalize] ),
        to_absolute: Support::Cache::RandomReplacement.new( CACHE_SIZES[:to_absolute] )
    }

    # @return [URI::Parser] cached URI parser
    def self.parser
        CACHE[__method__]
    end

    #
    # URL encodes a string.
    #
    # @param [String] string
    # @param [String, Regexp] bad_characters
    #   Class of characters to encode -- if {String} is passed, it should
    #   formatted as a regexp (for `Regexp.new`).
    #
    # @return   [String]    encoded string
    #
    def self.encode( string, bad_characters = nil )
        Addressable::URI.encode_component( *[string, bad_characters].compact )
    end

    #
    # URL decodes a string.
    #
    # @param [String] string
    #
    # @return   [String]
    #
    def self.decode( string )
        Addressable::URI.unencode( string )
    end

    #
    # Iteratively {.decode URL decodes} a {String} until there are no more
    # characters to be unescaped.
    #
    # @param [String] string
    #
    # @return   [String]
    #
    def self.deep_decode( string )
        string = decode( string ) while string =~ /%[a-fA-F0-9]{2}/
    end

    #
    # Cached version of {URI#initialize}, if there's a chance that the same
    # URL will be needed to be parsed multiple times you should use this method.
    #
    # @note This method's results are cached for performance reasons.
    #   If you plan on doing something destructive with its return value duplicate
    #   it first because there may be references to it elsewhere.
    #
    # @see URI#initialize
    #
    def self.parse( url )
        return url if !url || url.is_a?( Arachni::URI )
        CACHE[__method__][url] ||= begin
            new( url )
        rescue => e
            print_debug "Failed to parse '#{url}'."
            print_debug "Error: #{e}"
            print_debug_backtrace( e )
            nil
        end
    end

    #
    # {.normalize Normalizes} `url` and uses Ruby's core URI lib to parse it.
    #
    # @note This method's results are cached for performance reasons.
    #   If you plan on doing something destructive with its return value duplicate
    #   it first because there may be references to it elsewhere.
    #
    # @param    [String]    url     URL to parse
    #
    # @return   [URI]
    #
    def self.ruby_parse( url )
        return url if url.to_s.empty? || url.is_a?( ::URI )
        return if url.start_with? 'javascript:'

        CACHE[__method__][url] ||= begin
            ::URI::Generic.build( cheap_parse( url ) )
        rescue
            begin
                parser.parse( normalize( url ).dup )
            rescue => e
                print_debug "Failed to parse '#{url}'."
                print_debug "Error: #{e}"
                print_debug_backtrace( e )
                nil
            end
        end
    end

    #
    # Performs a parse that is less resource intensive than Ruby's URI lib's
    # method while normalizing the URL (will also discard the fragment and
    # path parameters).
    #
    # @param    [String]  url
    #
    # @return   [Hash]
    #   URL components (frozen):
    #
    #     * `:scheme` -- HTTP or HTTPS
    #     * `:userinfo` -- `username:password`
    #     * `:host`
    #     * `:port`
    #     * `:path`
    #     * `:query`
    #
    # @note This method's results are cached for performance reasons.
    #   If you plan on doing something destructive with its return value duplicate
    #   it first because there may be references to it elsewhere.
    #
    # @note The Hash is suitable for passing to `::URI::Generic.build` -- if
    #   however you plan on doing that you'll be better off just using
    #   {.ruby_parse} which does the same thing and caches the results for some
    #   extra schnell.
    #
    def self.cheap_parse( url )
        return if !url || url.empty?
        return if url.start_with? 'javascript:'

        cache = CACHE[__method__]

        url = url.to_s.dup

        # Remove the fragment if there is one.
        url   = url.split( '#', 2 )[0...-1].join if url.include?( '#' )
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

            # we're not smart enough for scheme-less URLs and if we're to go
            # into heuristics then there's no reason to not just use Addressable's parser
            if url.start_with?( '//' )
                return cache[c_url] = addressable_parse( c_url ).freeze
            end

            url = url.encode( 'UTF-8', undef: :replace, invalid: :replace )
            url = html_decode( url )

            dupped_url = url.dup
            has_path = true

            splits = url.split( ':' )
            if !splits.empty? && valid_schemes.include?( splits.first.downcase )
                splits = url.split( '://', 2 )
                components[:scheme] = splits.shift
                components[:scheme].downcase! if components[:scheme]

                if url = splits.shift
                    splits = url.split( '?' ).first.split( '@', 2 )

                    if splits.size > 1
                        components[:userinfo] = splits.first
                        url = splits.shift
                    end

                    if !splits.empty?
                        splits = splits.last.split( '/', 2 )
                        url = splits.last

                        splits = splits.first.split( ':', 2 )
                        if splits.size == 2
                            host = splits.first
                            components[:port] = Integer( splits.last ) if splits.last && !splits.last.empty?
                            components[:port] = nil if components[:port] == 80
                            url.gsub!( ':' + components[:port].to_s, '' )
                        else
                            host = splits.last
                        end

                        if components[:host] = host
                            url.gsub!( host, '' )
                            components[:host].downcase!
                        end
                    else
                        has_path = false
                    end
                else
                    has_path = false
                end
            end

            if has_path
                splits = url.split( '?', 2 )
                if components[:path] = splits.shift
                    components[:path] = '/' + components[:path] if components[:scheme]
                    components[:path].gsub!( /\/+/, '/' )

                    # Remove path params
                    components[:path] = components[:path].split( ';', 2 ).first

                    components[:path] =
                        encode( decode( components[:path] ),
                                Addressable::URI::CharacterClasses::PATH )

                    components[:path] = ::URI.encode( components[:path], ';' )
                end

                if c_url.include?( '?' ) && !(query = dupped_url.split( '?', 2 ).last).empty?
                    components[:query] = (query.split( '&', -1 ).map do |pair|
                        Addressable::URI.normalize_component( pair,
                            Addressable::URI::CharacterClasses::QUERY.sub( '\\&', '' )
                        )
                    end).join( '&' )
                end
            end

            components[:path] ||= components[:scheme] ? '/' : nil

            components.values.each( &:freeze )

            cache[c_url] = components.freeze
        rescue => e
            begin
                print_debug "Failed to fast-parse '#{c_url}', falling back to slow-parse."
                print_debug "Error: #{e}"
                print_debug_backtrace( e )

                cache[c_url] = addressable_parse( c_url ).freeze
            rescue => ex
                print_debug "Failed to parse '#{c_url}'."
                print_debug "Error: #{ex}"
                print_debug_backtrace( ex )

                cache[c_url] = :err
                nil
            end
        end
    end

    #
    # Performs a parse using the `URI::Addressable` lib while normalizing the
    # URL (will also discard the fragment).
    #
    # This method is not cached and solely exists as a fallback used by {.cheap_parse}.
    #
    # @param    [String]  url
    #
    # @return   [Hash]
    #   URL components:
    #
    #     * `:scheme` -- HTTP or HTTPS
    #     * `:userinfo` -- `username:password`
    #     * `:host`
    #     * `:port`
    #     * `:path`
    #     * `:query`
    #
    # @note The Hash is suitable for passing to `::URI::Generic.build` -- if
    #   however you plan on doing that you'll be better off just using
    #   {.ruby_parse} which does the same thing and caches the results for some
    #   extra schnell.
    #
    def self.addressable_parse( url )
        u = Addressable::URI.parse( html_decode( url.to_s ) ).normalize
        u.fragment = nil
        h = u.to_hash

        h[:path].gsub!( /\/+/, '/' ) if h[:path]
        if h[:user]
            h[:userinfo] = h.delete( :user )
            h[:userinfo] << ":#{h.delete( :password )}" if h[:password]
        end
        h
    end

    #
    # {.normalize Normalizes} and converts a `relative` URL to an absolute one
    # by merging in with a `reference` URL.
    #
    # Pretty much a cached version of {#to_absolute}.
    #
    # @note This method's results are cached for performance reasons.
    #   If you plan on doing something destructive with its return value duplicate
    #   it first because there may be references to it elsewhere.
    #
    # @param    [String]    relative
    # @param    [String]    reference    absolute url to use as a reference
    #
    # @return   [String]  absolute URL (frozen)
    #
    def self.to_absolute( relative, reference = Options.instance.url.to_s )
        return reference if !relative || relative.empty?
        key = relative + ' :: ' + reference

        cache = CACHE[__method__]
        begin
            if (v = cache[key]) && v == :err
                return
            elsif v
                return v
            end

            parsed_ref = parse( reference )

            # scheme-less URLs are expensive to parse so let's resolve the issue here
            relative = "#{parsed_ref.scheme}:#{relative}" if relative.start_with?( '//' )

            cache[key] = parse( relative ).to_absolute( parsed_ref ).to_s.freeze
        rescue
            cache[key] = :err
            nil
        end
    end

    #
    # Uses {.cheap_parse} to parse and normalize the URL and then converts
    # it to a common {String} format.
    #
    # @note This method's results are cached for performance reasons.
    #   If you plan on doing something destructive with its return value duplicate
    #   it first because there may be references to it elsewhere.
    #
    # @param    [String]    url
    #
    # @return   [String]    Normalized URL (frozen).
    #
    def self.normalize( url )
        return if !url || url.empty?

        cache = CACHE[__method__]

        url   = url.to_s.strip.dup
        c_url = url.to_s.strip.dup

        begin
            if (v = cache[url]) && v == :err
                return
            elsif v
                return v
            end

            components = cheap_parse( url )

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
        rescue => e
            print_debug "Failed to normalize '#{c_url}'."
            print_debug "Error: #{e}"
            print_debug_backtrace( e )

            cache[c_url] = :err
            nil
        end
    end

    #
    # {.normalize Normalizes} and parses the provided URL.
    #
    # Will discard the fragment component, if there is one.
    #
    # @param    [Arachni::URI, String, URI, Hash]    url
    #   {String} URL to parse, `URI` to convert, or a `Hash` holding URL components
    #   (for `URI::Generic.build`). Also accepts {Arachni::URI} for convenience.
    #
    def initialize( url )
        @parsed_url = case url
                          when String
                              self.class.ruby_parse( url )

                          when ::URI
                              url.dup

                          when Hash
                              ::URI::Generic.build( url )

                          when Arachni::URI
                              self.parsed_url = url.parsed_url

                          else
                              to_string = url.to_s rescue ''
                              msg = 'Argument must either be String, URI or Hash'
                              msg << " -- #{url.class.name} '#{to_string}' passed."
                              fail TypeError.new( msg )
                      end

        # We probably got it from the cache, dup it to avoid corrupting the cache
        # entries.
        @parsed_url = @parsed_url.dup

        fail Error, 'Failed to parse URL.' if !@parsed_url
    end

    def ==( other )
        to_s == other.to_s
    end

    #
    # Converts self into an absolute URL using `reference` to fill in the missing data.
    #
    # @param    [Arachni::URI, URI, String]    reference    Full, absolute URL.
    #
    # @return   [Arachni::URI]  Self, as an absolute URL.
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

    # @return   [String]
    #   The URL up to its resource component (query, fragment, etc).
    def without_query
        to_s.split( '?', 2 ).first.to_s
    end

    # @return   [String]    The extension of the URI resource.
    def resource_extension
        resource_name = path.split( '/' ).last.to_s
        return if !resource_name.include?( '.' )
        resource_name.split( '.' ).last
    end

    # @return   [String]
    #   The URL up to its path component (no resource name, query, fragment, etc).
    def up_to_path
        return if !path
        uri_path = path.dup

        uri_path = File.dirname( uri_path ) if !File.extname( path ).empty?

        uri_path << '/' if uri_path[-1] != '/'

        uri_str = "#{scheme}://#{host}"
        uri_str << ':' + port.to_s if port && port != 80
        uri_str << uri_path
    end

    # @return [String]  domain_name.tld
    def domain
        return host if ip_address?

        s = host.split( '.' )
        return s.first if s.size == 1
        return host if s.size == 2

        s[1..-1].join( '.' )
    end

    # @return   [Boolean]
    #   `true` if the URI contains an IP address, `false` otherwise.
    def ip_address?
        !(IPAddr.new( host ) rescue nil).nil?
    end

    #
    # Checks if self exceeds a given directory `depth`.
    #
    # @param    [Integer]   depth   Depth to check for.
    #
    # @return   [Bool]  `true` if self is deeper than `depth`, `false` otherwise.
    #
    def too_deep?( depth )
        depth.to_i > 0 && (depth + 1) <= path.to_s.count( '/' )
    end

    #
    # Checks if self should be excluded based on the provided `patterns`.
    #
    # @param    [Array<Regexp,String>] patterns
    #
    # @return   [Bool]  `true` if self matches a pattern, `false` otherwise.
    #
    def exclude?( patterns )
        fail TypeError.new( 'Array<Regexp,String> expected, got nil instead' ) if patterns.nil?
        ensure_patterns( patterns ).each { |pattern| return true if to_s =~ pattern }
        false
    end

    #
    # Checks if self should be included based on the provided `patterns`.
    #
    # @param    [Array<Regexp,String>] patterns
    #
    # @return   [Bool]
    #   `true` if self matches a pattern (or `patterns` are `nil` or empty),
    #   `false` otherwise.
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
    # @param    [Arachni::URI, URI, Hash, String]    other  Reference URL.
    #
    # @return   [Bool]
    #   `true` if self is in the same domain as the `other` URL, false otherwise.
    #
    def in_domain?( include_subdomain, other )
        return true if !other

        other = self.class.new( other ) if !other.is_a?( Arachni::URI )
        include_subdomain ? other.host == host : other.domain == domain
    rescue
        false
    end

    def mailto?
        scheme == 'mailto'
    end

    def query=( q )
        return if q.to_s.empty?
        @parsed_url.query = q
    end

    # @return   [String]    URL
    def to_s
        @parsed_url.to_s
    end

    def dup
        return if to_s.empty?
        self.class.new( to_s )
    end

    def _dump( _ )
        to_s
    end

    def self._load( url )
        new url
    end

    def hash
        to_s.hash
    end

    def persistent_hash
        to_s.persistent_hash
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

    #
    # Delegates unimplemented methods to Ruby's `URI::Generic` class for
    # compatibility.
    #
    def method_missing( sym, *args, &block )
        if @parsed_url.respond_to?( sym )
            @parsed_url.send( sym, *args, &block )
        else
            super
        end
    end

    def respond_to?( *args )
        super || @parsed_url.respond_to?( *args )
    end

end
end
