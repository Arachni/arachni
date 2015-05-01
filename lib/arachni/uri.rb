=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'uri'
require 'ipaddr'
require 'addressable/uri'
require_relative 'uri/scope'

module Arachni

    # Helper method which parses a URL using {Arachni::URI.parse}.
    #
    # @see Arachni::URI.parse
    def self.URI( uri )
        Arachni::URI.parse( uri )
    end

# The URI class automatically normalizes the URLs it is passed to parse
# while maintaining compatibility with Ruby's URI core class by delegating
# missing methods to it -- thus, you can treat it like a Ruby URI and enjoy some
# extra perks along the way.
#
# It also provides *cached* (to maintain a low latency) helper class methods to
# ease common operations such as:
#
# * {.normalize Normalization}.
# * Parsing to {.parse Arachni::URI} (see also {.URI}), {.ruby_parse ::URI} or
#   {.fast_parse Hash} objects.
# * Conversion to {.to_absolute absolute URLs}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class URI
    include UI::Output
    extend  UI::Output

    include Utilities
    extend  Utilities

    # {URI} error namespace.
    #
    # All {URI} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Arachni::Error
    end

    CACHE_SIZES = {
        parse:       600,
        ruby_parse:  600,
        fast_parse:  600,
        normalize:   1000,
        to_absolute: 1000
    }

    CACHE = {
        parser:      ::URI::Parser.new,
        ruby_parse:  Support::Cache::RandomReplacement.new( CACHE_SIZES[:ruby_parse] ),
        parse:       Support::Cache::RandomReplacement.new( CACHE_SIZES[:parse] ),
        fast_parse:  Support::Cache::RandomReplacement.new( CACHE_SIZES[:fast_parse] ),
        normalize:   Support::Cache::RandomReplacement.new( CACHE_SIZES[:normalize] ),
        to_absolute: Support::Cache::RandomReplacement.new( CACHE_SIZES[:to_absolute] )
    }

    class <<self

        # @return [URI::Parser] cached URI parser
        def parser
            CACHE[__method__]
        end

        # URL encodes a string.
        #
        # @param [String] string
        # @param [String, Regexp] bad_characters
        #   Class of characters to encode -- if {String} is passed, it should
        #   formatted as a regexp (for `Regexp.new`).
        #
        # @return   [String]
        #   Encoded string.
        def encode( string, bad_characters = nil )
            Addressable::URI.encode_component( *[string, bad_characters].compact )
        end

        # URL decodes a string.
        #
        # @param [String] string
        #
        # @return   [String]
        def decode( string )
            Addressable::URI.unencode( string )
        end

        # @note This method's results are cached for performance reasons.
        #   If you plan on doing something destructive with its return value
        #   duplicate it first because there may be references to it elsewhere.
        #
        # Cached version of {URI#initialize}, if there's a chance that the same
        # URL will be needed to be parsed multiple times you should use this method.
        #
        # @see URI#initialize
        def parse( url )
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

        # @note This method's results are cached for performance reasons.
        #   If you plan on doing something destructive with its return value
        #   duplicate it first because there may be references to it elsewhere.
        #
        # {.normalize Normalizes} `url` and uses Ruby's core URI lib to parse it.
        #
        # @param    [String]    url
        #   URL to parse
        #
        # @return   [URI]
        def ruby_parse( url )
            return url if url.to_s.empty? || url.is_a?( ::URI )
            return if url.downcase.start_with? 'javascript:'

            CACHE[__method__][url] ||= begin
                ::URI::Generic.build( fast_parse( url ) )
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

        # @note This method's results are cached for performance reasons.
        #   If you plan on doing something destructive with its return value
        #   duplicate it first because there may be references to it elsewhere.
        #
        # @note The Hash is suitable for passing to `::URI::Generic.build` -- if
        #   however you plan on doing that you'll be better off just using
        #   {.ruby_parse} which does the same thing and caches the results for some
        #   extra schnell.
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
        def fast_parse( url )
            return if !url || url.empty?
            return if url.downcase.start_with? 'javascript:'

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

                # We're not smart enough for scheme-less URLs and if we're to go
                # into heuristics then there's no reason to not just use
                # Addressable's parser.
                if url.start_with?( '//' )
                    return cache[c_url] = addressable_parse( c_url ).freeze
                end

                url = url.recode
                url = html_decode( url )

                dupped_url = url.dup
                has_path = true

                splits = url.split( ':' )
                if !splits.empty? && valid_schemes.include?( splits.first.downcase )
                    splits = url.split( '://', 2 )
                    components[:scheme] = splits.shift
                    components[:scheme].downcase! if components[:scheme]

                    if url = splits.shift
                        splits = url.to_s.split( '?' ).first.to_s.split( '@', 2 )

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

                                if splits.last && !splits.last.empty?
                                    components[:port] = Integer( splits.last )
                                end

                                if components[:port] == 80
                                    components[:port] = nil
                                end

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
                    if (components[:path] = splits.shift)
                        if components[:scheme]
                            components[:path] = '/' + components[:path]
                        end

                        components[:path].gsub!( /\/+/, '/' )

                        # Remove path params
                        components[:path] = components[:path].split( ';', 2 ).first

                        if components[:path]
                            components[:path] =
                                encode( decode( components[:path] ),
                                        Addressable::URI::CharacterClasses::PATH )

                            components[:path] = ::URI.encode( components[:path], ';' )
                        end
                    end

                    if c_url.include?( '?' ) &&
                        !(query = dupped_url.split( '?', 2 ).last).empty?

                        components[:query] = (query.split( '&', -1 ).map do |pair|
                            Addressable::URI.normalize_component( pair,
                                Addressable::URI::CharacterClasses::QUERY.sub( '\\&', '' )
                            )
                        end).join( '&' )
                    end
                end

                components[:path] ||= components[:scheme] ? '/' : nil

                components.values.each(&:freeze)

                cache[c_url] = components.freeze
            rescue => e
                begin
                    print_debug "Failed to fast-parse '#{c_url}', falling back to slow-parse."
                    print_debug "Error: #{e}"
                    print_debug_backtrace( e )

                    cache[c_url] = addressable_parse( c_url.recode ).freeze
                rescue => ex
                    print_debug "Failed to parse '#{c_url}'."
                    print_debug "Error: #{ex}"
                    print_debug_backtrace( ex )

                    cache[c_url] = :err
                    nil
                end
            end
        end

        # @note The Hash is suitable for passing to `::URI::Generic.build` -- if
        #   however you plan on doing that you'll be better off just using
        #   {.ruby_parse} which does the same thing and caches the results for
        #   some extra schnell.
        #
        # Performs a parse using the `URI::Addressable` lib while normalizing the
        # URL (will also discard the fragment).
        #
        # This method is not cached and solely exists as a fallback used by {.fast_parse}.
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
        def addressable_parse( url )
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

        # @note This method's results are cached for performance reasons.
        #   If you plan on doing something destructive with its return value
        #   duplicate it first because there may be references to it elsewhere.
        #
        # {.normalize Normalizes} and converts a `relative` URL to an absolute
        # one by merging in with a `reference` URL.
        #
        # Pretty much a cached version of {#to_absolute}.
        #
        # @param    [String]    relative
        # @param    [String]    reference
        #   Absolute url to use as a reference.
        #
        # @return   [String]
        #   Absolute URL (frozen).
        def to_absolute( relative, reference = Options.instance.url.to_s )
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

                if relative.start_with?( '//' )
                    # Scheme-less URLs are expensive to parse so let's resolve
                    # the issue here.
                    relative = "#{parsed_ref.scheme}:#{relative}"
                end

                cache[key] = parse( relative ).to_absolute( parsed_ref ).to_s.freeze
            rescue
                cache[key] = :err
                nil
            end
        end

        # @note This method's results are cached for performance reasons.
        #   If you plan on doing something destructive with its return value
        #   duplicate it first because there may be references to it elsewhere.
        #
        # Uses {.fast_parse} to parse and normalize the URL and then converts
        # it to a common {String} format.
        #
        # @param    [String]    url
        #
        # @return   [String]
        #   Normalized URL (frozen).
        def normalize( url )
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

                components = fast_parse( url )

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

        # @param    [String]    url
        # @param    [Hash<Regexp => String>]    rules
        #   Regular expression and substitution pairs.
        #
        # @return  [String]
        #   Rewritten URL.
        def rewrite( url, rules = Arachni::Options.scope.url_rewrites )
            parse( url ).rewrite( rules ).to_s
        end

        # Extracts inputs from a URL query.
        #
        # @param    [String]    url
        #
        # @return   [Hash]
        def parse_query( url )
            parsed = parse( url )
            return {} if !parsed

            parse( url ).query_parameters
        end

        # @param    [String]    url
        #   URL to check.
        #
        # @return   [Bool]
        #   `true` is the URL is full and absolute, `false` otherwise.
        def full_and_absolute?( url )
            return false if url.to_s.empty?

            parsed = parse( url.to_s )
            return false if !parsed

            parsed.absolute?
        end
    end

    # @note Will discard the fragment component, if there is one.
    #
    # {.normalize Normalizes} and parses the provided URL.
    #
    # @param    [Arachni::URI, String, URI, Hash]    url
    #   {String} URL to parse, `URI` to convert, or a `Hash` holding URL components
    #   (for `URI::Generic.build`). Also accepts {Arachni::URI} for convenience.
    def initialize( url )
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
                              to_string = url.to_s rescue ''
                              msg = 'Argument must either be String, URI or Hash'
                              msg << " -- #{url.class.name} '#{to_string}' passed."
                              fail ArgumentError.new( msg )
                      end

        fail Error, 'Failed to parse URL.' if !@parsed_url

        # We probably got it from the cache, dup it to avoid corrupting the cache
        # entries.
        @parsed_url = @parsed_url.dup
    end

    # @return   [Scope]
    def scope
        @scope ||= Scope.new( self )
    end

    def ==( other )
        to_s == other.to_s
    end

    # Converts self into an absolute URL using `reference` to fill in the
    # missing data.
    #
    # @param    [Arachni::URI, URI, String]    reference
    #   Full, absolute URL.
    #
    # @return   [Arachni::URI]
    #   Self, as an absolute URL.
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

    # @return   [String]
    #   Name of the resource.
    def resource_name
        path.split( '/' ).last
    end

    # @return   [String, nil]
    #   The extension of the URI {#file_name}, `nil` if there is none.
    def resource_extension
        name = resource_name.to_s
        return if !name.include?( '.' )

        name.split( '.' ).last
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

    # @return [String]
    #   `domain_name.tld`
    def domain
        return if !host
        return host if ip_address?

        s = host.split( '.' )
        return s.first if s.size == 1
        return host if s.size == 2

        s[1..-1].join( '.' )
    end

    # @param    [Hash<Regexp => String>]    rules
    #   Regular expression and substitution pairs.
    #
    # @return  [URI]
    #   Rewritten URL.
    def rewrite( rules = Arachni::Options.scope.url_rewrites )
        as_string = self.to_s

        rules.each do |args|
            if (rewritten = as_string.gsub( *args )) != as_string
                return Arachni::URI( rewritten )
            end
        end

        self.dup
    end

    # @return   [Boolean]
    #   `true` if the URI contains an IP address, `false` otherwise.
    def ip_address?
        !(IPAddr.new( host ) rescue nil).nil?
    end

    def mailto?
        scheme == 'mailto'
    end

    def query=( q )
        q = q.to_s
        q = nil if q.empty?

        @parsed_url.query = q
    end

    # @return   [Hash]
    #   Extracted inputs from a URL query.
    def query_parameters
        q = self.query
        return {} if q.to_s.empty?

        q.split( '&' ).inject( {} ) do |h, pair|
            name, value = pair.split( '=', 2 )
            h[::URI.decode( name.to_s )] = ::URI.decode( value.to_s )
            h
        end
    end

    # @return   [String]
    def to_s
        @parsed_url.to_s
    end

    def dup
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

    # Delegates unimplemented methods to Ruby's `URI::Generic` class for
    # compatibility.
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

    protected

    def parsed_url
        @parsed_url
    end

    def parsed_url=( url )
        @parsed_url = url
    end

end
end
