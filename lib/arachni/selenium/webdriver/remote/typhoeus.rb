require 'typhoeus'

module Selenium
module WebDriver
module Remote
module Http

# The default client uses Threads to track timeout and we don't want that,
# each threads uses about 1MB of RAM.
#
# However, this one results in memory violations on Windows, so it should only
# be used on *nix.
class Typhoeus < Common

    private

    def request( verb, url, headers, payload )
        url = url.to_s

        headers.delete 'Content-Length'

        options = {
            headers:        headers,
            maxredirs:      MAX_REDIRECTS,
            followlocation: true,
            # Small trick to cancel out http_proxy env variables which would
            # otherwise be honoured by libcurl and hinder browser communications.
            proxy:          ''
        }

        options[:timeout] = @timeout if @timeout

        case verb
            when :post, :put
                options[:body] = payload.to_s

            when :get, :delete, :head
            else
                raise Error::WebDriverError, "Unknown HTTP verb: #{verb.inspect}"
        end

        response = ::Typhoeus::Request.send( verb, url, options )

        if response.timed_out?
            raise Timeout::Error, "Request timed out: #{verb} #{url}\n#{payload}"
        end

        create_response extract_real_code( response ), response.body,
                        response.headers['Content-Type']
    end

    def extract_real_code( response )
        # Typhoeus sometimes gets confused when running under JRuby from
        # multiple threads:
        #   https://github.com/typhoeus/typhoeus/issues/411
        if Arachni.jruby?
            code = response.response_headers.match( /HTTP\/1\.\d\s(\d+)\s/ )[1] || 0
            code.to_i
        else
            response.code
        end
    end

end

end
end
end
end
