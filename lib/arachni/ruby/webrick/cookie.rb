=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
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
