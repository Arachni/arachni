=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module HTTP

# Basic CookieJar implementation.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class CookieJar
    include Utilities

    # {CookieJar} error namespace.
    #
    # All {CookieJar} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Arachni::HTTP::Error

        # Raised when a CookieJar file could not be found at the specified location.
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
        class CookieJarFileNotFound < Error
        end
    end

    # Same as {#initialize}.
    #
    # @return   [Arachni::HTTP::CookieJar]
    def self.from_file( *args )
        new.load( *args )
    end

    # @param    [String]    cookie_jar_file
    #   Path to a Netscape cookie-jar.
    def initialize( cookie_jar_file = nil )
        @cookies = {}
        load( cookie_jar_file ) if cookie_jar_file
    end

    # Loads cookies from a Netscape cookiejar file.
    #
    # @param    [String]    cookie_jar_file
    #   Path to a Netscape cookie-jar.
    # @param    [String]    url
    #   Cookie owner.
    #
    # @return   [CookieJar]  self
    def load( cookie_jar_file, url = '' )
        if !File.exist?( cookie_jar_file )
            fail Error::CookieJarFileNotFound,
                 "Cookie-jar '#{cookie_jar_file}' doesn't exist."
        end

        update( cookies_from_file( url, cookie_jar_file ) )
        self
    end

    # @param    [Cookie, Array<Cookie>]  cookies
    #   Cookies with which to update the cookie-jar.
    #
    # @return   [CookieJar]
    #   `self`
    def <<( cookies )
        [cookies].flatten.each do |cookie|
            next if !cookie
            set_cookie( cookie )
        end
        self
    end

    # Updates the jar with `cookies`.
    #
    # @param    [Array<String, Hash, Cookie>]  cookies
    #   Cookies with which to update the cookie-jar.
    #
    # @return   [CookieJar]  self
    def update( cookies )
        [cookies].flatten.each do |c|
            next if !c

            self << case c
                        when String
                            Cookie.from_set_cookie( ::Arachni::Options.url.to_s, c )

                        when Hash
                            next if c.empty?

                            if c.size > 1
                                Cookie.new( { url: ::Arachni::Options.url.to_s }.merge( c ) )
                            else
                                Cookie.new( url: ::Arachni::Options.url.to_s, inputs: c )
                            end
                        when Cookie
                            c
                    end
        end
        self
    end

    # @param    [String]    url
    #   URL for which to retrieve cookies.
    #
    # @return   [Array<Cookie>]
    #   URL which should be sent to the resource at `url`.
    def for_url( url )
        uri = to_uri( url )
        request_path   = uri.path
        request_domain = uri.host

        return [] if !request_domain || !request_path

        unique_cookies = {}
        @cookies.values.map do |cookie|
            if cookie.expired? || !request_path.start_with?( cookie.path ) ||
                !in_domain?( cookie.domain, request_domain )
                next
            end

            unique_cookies[cookie.name] = cookie
        end

        unique_cookies.values.sort do |lhs, rhs|
            rhs.path.length <=> lhs.path.length
        end
    end

    # @param    [Bool]  include_expired
    #   Include expired cookies.
    #
    # @return   [Array<Cookie>]
    #   All cookies.
    def cookies( include_expired = false )
        @cookies.values.map do |cookie|
            next if !include_expired && cookie.expired?
            cookie
        end.compact
    end

    # @param    [CookieJar] other
    def merge!( other )
        update other.cookies
    end

    # Empties the cookiejar.
    def clear
        @cookies.clear
    end

    # @return   [Bool]
    #   `true` if cookiejar is empty, `false` otherwise.
    def empty?
        @cookies.empty?
    end

    # @return   [Bool]
    #   `true` if cookiejar is not empty, `false` otherwise.
    def any?
        !empty?
    end

    # @param    [CookieJar] other
    def ==( other )
        hash == other.hash
    end

    def hash
        cookies.map(&:to_s).hash
    end

    private

    def get_cookie( cookie )
        @cookies[make_key( cookie )]
    end

    def set_cookie( cookie )
        key = make_key( cookie )

        if (existing = @cookies[key]) &&
            cookie.to_set_cookie == existing.to_set_cookie
            return
        end

        @cookies[key] = cookie.dup.tap { |c| c.page = nil }
    end

    def make_key( cookie )
        "#{cookie.domain}:#{cookie.path}:#{cookie.name}".hash
    end

    def in_domain?( cookie_domain, request_domain )
        request_domain == cookie_domain ||
            (
                cookie_domain.start_with?( '.' ) &&
                    request_domain.end_with?( cookie_domain[1...cookie_domain.size] )
            )
    end

    def to_uri( url )
        u = url.is_a?( Arachni::URI ) ? url : Arachni::URI( url.to_s )

        if !u
            fail "Failed to parse: #{url}"
        end

        if !u.absolute?
            fail ArgumentError,
                 "Complete absolute URL required, got: #{url} (#{u})"
        end

        u
    end

end
end
end
