=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module UI
module Web

#
# General utility methods.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
module Utilities

    #
    # @see CGI.escapeHTML
    #
    def escape( str )
        CGI.escapeHTML( str )
    end

    #
    # @see CGI.unescapeHTML
    #
    def unescape( str )
        CGI.unescapeHTML( str )
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

    def parse_datetime( datetime )
        date, time = datetime.split( ' ' )

        month, day, year = date.split( '/' )
        hour, minute     = time.split( ':' )

        Time.new( year, month, day, hour, minute )
    end

    #
    # Converts a port to a URL instance.
    #
    # @param    [Integer]   port
    #
    def port_to_url( port, dispatcher_url, no_scheme = nil )
        uri = URI( dispatcher_url )
        uri.port = port.to_i
        uri = uri.to_s

        uri = remove_proto( uri ) if no_scheme
        return uri
    end

    #
    # Removes the protocol from URL string.
    #
    # @param    [String]    url
    #
    # @return   [String]
    #
    def remove_proto( url )
        url.gsub!( 'http://', '' )
        escape( url.gsub( 'https://', '' ) )
    end

end
end
end
end
