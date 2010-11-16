=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'webrick/httpproxy'
require 'stringio'
require 'zlib'
require 'open-uri'

module Arachni
module Plugins

class Proxy
    #
    # We add our own type of WEBrick::HTTPProxyServer class that supports
    # notifications when the user tries to access a resource irrelevant
    # to the scan and does not restrict header exchange.
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class Server < WEBrick::HTTPProxyServer

        def choose_header(src, dst)
            connections = split_field(src['connection'])
            src.each{|key, value|
                key = key.downcase
                if HopByHop.member?(key)          || # RFC2616: 13.5.1
                   connections.member?(key)       || # RFC2616: 14.10
                   # ShouldNotTransfer.member?(key)    # pragmatics
                  @logger.debug("choose_header: `#{key}: #{value}'")
                  next
                end
            dst[key] = value
          }
        end

        def service( req, res )
            exclude_reasons = @config[:ProxyURITest].call( req.unparsed_uri )

            if( exclude_reasons.empty? )
                super( req, res )
            else
                notify( exclude_reasons, req, res )
            end
        end

        def notify( reasons, req, res )
            res.header['content-type'] = 'text/plain'
            res.header.delete( 'content-encoding' )

            res.body << reasons.map{ |msg| " *  #{msg}" }.join( "\n" )
        end
    end
end

end
end
