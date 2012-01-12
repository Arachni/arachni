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
    # @version: 0.1.2
    #
    class Server < WEBrick::HTTPProxyServer

        def choose_header(src, dst)
            connections = split_field(src['connection'])
            src.each{|key, value|
                key = key.downcase
                if HopByHop.member?(key)          || # RFC2616: 13.5.1
                   connections.member?(key)       #|| # RFC2616: 14.10
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

            res.body << reasons.pop + "\n"
            res.body << reasons.map{ |msg| "  *  #{msg}" }.join( "\n" )
        end
    end
end

end
end
