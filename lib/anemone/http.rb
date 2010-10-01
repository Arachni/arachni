=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end
require 'rubygems'
require 'anemone'

#
# Overides Anemone's HTTP class methods:
#  o refresh_connection( ): added proxy support
#  o get_response( ): upped the retry counter to 7 and generalized exception handling
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Anemone::HTTP

    include Arachni::UI::Output

    def refresh_connection( url )

        http = Net::HTTP.new( url.host, url.port,
        @opts['proxy_addr'], @opts['proxy_port'],
        @opts['proxy_user'], @opts['proxy_pass'] )

        if url.scheme == 'https'
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        @connections[url.host][url.port] = http.start
    end

    #
    # Get an HTTPResponse for *url*, sending the appropriate User-Agent string
    #
    def get_response(url, referer = nil)
        full_path = url.query.nil? ? url.path : "#{url.path}?#{url.query}"

        opts = {}
        opts['User-Agent'] = user_agent if user_agent
        opts['Referer'] = referer.to_s if referer
        opts['Cookie'] = @cookie_store.to_s unless @cookie_store.empty? || (!accept_cookies? && @opts[:cookies].nil?)

        retries = 0
        begin
            start = Time.now()
            response = connection(url).get(full_path, opts)
            finish = Time.now()
            response_time = ((finish - start) * 1000).round
            @cookie_store.merge!(response['Set-Cookie']) if accept_cookies?
            return response, response_time
        rescue Exception => e
            retries += 1
            
            print_error( e.to_s )
            print_info( ( 7 - retries ).to_s +
                ' retries remaining for url: ' + url.to_s )
                
            print_debug_backtrace( e )
            refresh_connection(url)
            retry unless retries > 7
        end
    end

end
