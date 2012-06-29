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

module Arachni
class HTTP

#
# Basic CookieJar implementation.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class CookieJar
    include Arachni::Utilities

    #
    # Same as {#initialize}.
    #
    # @return   [Arachni::HTTP::CookieJar]
    #
    def self.from_file( *args )
        new.load( *args )
    end

    # @param    [String]    cookie_jar_file path to a Netscape cookie-jar
    def initialize( cookie_jar_file = nil )
        @domains = {}
        load( cookie_jar_file ) if cookie_jar_file
    end

    #
    # Loads cookies from a Netscape cookiejar file
    #
    # @param    [String]    cookie_jar_file path to a Netscape cookie-jar
    # @param    [String]    url     cookie owner
    #
    # @return   [Arachni::HTTP::CookieJar]  self
    #
    def load( cookie_jar_file, url = '' )
        # make sure that the provided cookie-jar file exists
        if !File.exist?( cookie_jar_file )
            raise( Arachni::Exceptions::NoCookieJar,
                   'Cookie-jar \'' + cookie_jar_file + '\' doesn\'t exist.' )
        end
        update( cookies_from_file( url, cookie_jar_file ) )
        self
    end

    #
    # Updates the jar with +cookie+.
    #
    # @param    [Arachni::Parser::Element::Cookie]  cookie
    #
    # @return   [Arachni::HTTP::CookieJar]  self
    #
    def <<( cookie )
        ((@domains[cookie.domain] ||= {})[cookie.path] ||= {})[cookie.name] = cookie.dup
        self
    end

    #
    # Updates the jar with +cookies+.
    #
    # @param    [Array<Arachni::Parser::Element::Cookie>]  cookies
    #
    # @return   [Arachni::HTTP::CookieJar]  self
    #
    def update( cookies )
        [cookies].flatten.compact.each { |c| self << c }
        self
    end

    #
    # Gets cookies for a specific +url+.
    #
    # @param    [String]    url
    #
    # @return   [Array<Arachni::Parser::Element::Cookie>]
    #
    def for_url( url )
        uri = to_uri( url )
        request_path   = uri.path
        request_domain = uri.host

        return [] if !request_domain || !request_path

        @domains.map do |domain, paths|
            next if !in_domain?( domain, request_domain )

            paths.map do |path, cookies|
                next if !request_path.start_with?( path )

                cookies.values.reject{ |c| c.expired? }
            end
        end.flatten.compact.sort do |lhs, rhs|
            rhs.path.length <=> lhs.path.length
        end
    end

    #
    # Returns all cookies
    #
    # @param    [Bool]  include_expired    include expired cookies
    #
    # @return   [Array<Arachni::Parser::Element::Cookie>]
    #
    def cookies( include_expired = false )
        @domains.values.map do |paths|
            paths.values.map do |cookies|
                if !include_expired
                    cookies.values.reject{ |c| c.expired? }
                else
                    cookies.values
                end
            end
        end.flatten.compact
    end

    # Empties the cookiejar
    def clear
        @domains.clear
    end

    # @return   [Bool]  +true+ if cookiejar is empty, +false+ otherwise
    def empty?
        @domains.empty?
    end

    # @return   [Bool]  +true+ if cookiejar is not empty, +false+ otherwise
    def any?
        !empty?
    end

    private

    def in_domain?( cookie_domain, request_domain )
        request_domain == cookie_domain ||
            ( cookie_domain.start_with?( '.' ) &&
              request_domain.end_with?( cookie_domain[1...cookie_domain.size] )
            )
    end

    def to_uri( url )
        u = url.is_a?( ::URI ) || url.is_a?( Arachni::URI ) ? url : uri_parse( url.to_s )
        fail 'Complete absolute URL required.' if u.relative?
        u
    end

end
end
end
