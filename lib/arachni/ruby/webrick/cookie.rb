=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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

class WEBrick::Cookie
    attr_accessor :httponly

    class << self
        alias :old_parse_set_cookie :parse_set_cookie
    end

    def self.parse_set_cookie( str )
        cookie = old_parse_set_cookie( str )
        cookie.httponly = str.split( ';' ).map { |f| f.downcase.strip }.
            include?( 'httponly' )
        cookie
    end
end
