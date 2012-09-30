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
module UI
module Web

#
# General utility methods.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#
# @version 0.1
#
module Utilities

    #
    # Escapes HTML chars.
    #
    # @param    [String]    str
    #
    # @return   [String]
    #
    # @see CGI.escapeHTML
    #
    def escape( str )
        CGI.escapeHTML( str || '' )
    end

    #
    # Unescapes HTML chars.
    #
    # @param    [String]    str
    #
    # @return   [String]
    #
    # @see CGI.unescapeHTML
    #
    def unescape( str )
        CGI.unescapeHTML( str || '' )
    end

    #
    # Recursively escapes all HTML characters.
    #
    # @param    [Hash]  hash
    #
    # @return   [Hash]
    #
    def escape_hash( hash )
        hash.each_pair {
            |k, v|
            hash[k] = escape( hash[k] ) if hash[k].is_a?( String )
            hash[k] = escape_hash( v ) if v.is_a? Hash
        }

        return hash
    end

    #
    # Recursively unescapes all HTML characters.
    #
    # @param    [Hash]  hash
    #
    # @return   [Hash]
    #
    def unescape_hash( hash )
        hash.each_pair {
            |k, v|
            hash[k] = unescape( hash[k] ) if hash[k].is_a?( String )
            hash[k] = unescape_hash( v ) if v.is_a? Hash
        }

        return hash
    end

    #
    # Parses datetime strings such as 07/23/2011 15:34 into Time objects.
    #
    # @param    [String]    datetime
    #
    # @return   [Time]
    #
    def parse_datetime( datetime )
        date, time = datetime.split( ' ' )

        month, day, year = date.split( '/' )
        hour, minute     = time.split( ':' )

        Time.new( year, month, day, hour, minute )
    end

    #
    # Removes the protocol from URL string.
    #
    # @param    [String]    url
    #
    # @return   [String]
    #
    def remove_proto( url )
        url
        #begin
        #    url = URI.parse( url )
        #    scheme = url.scheme + '://'
        #    escape( url.to_s.gsub( scheme, '' ) )
        #rescue
        #    return url
        #end
    end

end
end
end
end
