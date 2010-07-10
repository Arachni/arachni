=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end
require 'rubygems'
require 'anemone'

#
# Overides Anemone's HTTP class method refresh_connection( url )
# adding proxy support
#
class Anemone::HTTP

    def refresh_connection( url )

        # TODO: remove global vars
        http = Net::HTTP.new( url.host, url.port,
        $runtime_args[:proxy_addr], $runtime_args[:proxy_port],
        $runtime_args[:proxy_user], $runtime_args[:proxy_pass] )

        if url.scheme == 'https'
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        @connections[url.host][url.port] = http.start
    end

end
