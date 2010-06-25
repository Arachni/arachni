=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

require 'net/http'

#
# Unfortunaetely Anemone doesn't support HTTP authentication 
# so we need to override Net::HTTPHeader.initialize_http_header( )
# 
# May not be such a bad thing after all, since it'll apply
# to the whole system but it feels kinda dirty.
#
module Net::HTTPHeader
  
  def initialize_http_header( initheader )
    @header = {}
    return unless initheader
    initheader.each do |key, value|
      warn "net/http: warning: duplicated HTTP header: #{key}" if key?(key) and $VERBOSE
      @header[key.downcase] = [value.strip]
    end
    
    # this is our little modification
    basic_auth( $opts[:url].user, $opts[:url].password )
  end
  
end
