=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end
require 'net/http'

#
# Unfortunaetely Anemone doesn't support HTTP authentication<br/>
# so we need to get to the core and override Net::HTTPHeader.initialize_http_header( )
#
# May not be such a bad thing after all since it'll apply<br/>
# to the whole system but it feels kinda dirty.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1-pre
#

module Net::HTTPHeader

alias :old_initialize_http_header :initialize_http_header

def initialize_http_header( initheader )
    old_initialize_http_header( initheader )

    begin
        # TODO: remove global vars
        url = URI.parse( URI.encode( $runtime_args[:url] ) )
        
        # this is our little modification
        basic_auth( url.user, url.password )
    end
end

end
