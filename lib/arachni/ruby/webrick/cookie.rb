=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
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
