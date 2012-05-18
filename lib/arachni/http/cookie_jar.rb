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
# TODO: Implement proper tailmatching
#
class CookieJar
    include Arachni::Module::Utilities

    def self.from_file( *args )
        new.load( *args )
    end

    def initialize( cookie_jar_file = nil )
        @domains = {}
        load( cookie_jar_file ) if cookie_jar_file
    end

    def load( cookie_jar_file, url = '' )
        # make sure that the provided cookie-jar file exists
        if !File.exist?( cookie_jar_file )
            raise( Arachni::Exceptions::NoCookieJar,
                   'Cookie-jar \'' + cookie_jar_file + '\' doesn\'t exist.' )
        end
        update( cookies_from_file( url, cookie_jar_file ) )
    end

    def <<( cookie )
        ((@domains[cookie.domain] ||= {})[cookie.path] ||= {})[cookie.name] = cookie.dup
    end

    def update( cookies )
        [cookies].flatten.compact.each { |c| self << c }
    end

    def get_cookies( url )
        uri = to_uri( url )
        request_domain = uri.host
        request_path = uri.path

        return [] if !request_domain || !request_path

        @domains.map do |domain, paths|
            next if (request_domain != domain) && ( '.' + request_domain != domain)
            paths.map do |path, cookies|
                next if !request_path.start_with?( path )
                cookies.values.reject{ |c| c.expired? }
            end
        end.flatten.compact.sort do |lhs, rhs|
            rhs.path.length <=> lhs.path.length
        end
    end

    def cookies( with_expired = false )
        @domains.values.map do |paths|
            paths.values.map do |cookies|
                if !with_expired
                    cookies.values.reject{ |c| c.expired? }
                else
                    cookies.values
                end
            end
        end.flatten.compact
    end

    def to_s( url )
        get_cookies( url ).map{ |c| c.to_s }.join( ';' )
    end

    private

    def to_uri( url )
        url.is_a?( URI ) ? url : uri_parse( url )
    end

end
end
end
