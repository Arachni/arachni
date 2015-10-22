require 'typhoeus'

module Selenium
module WebDriver
module Remote

module Http

# The default client is unusably slow on platforms where Ruby IO is lacking in
# performance, like Windows.
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

        # $WATIR_REQ_COUNT ||= 0
        # $WATIR_REQ_COUNT += 1

        # if url.end_with?( '/cookie' )
        # if !url.end_with?( '/url' ) && response.time > 0.1
        # if response.code == 500
            # ap "#{$WATIR_REQ_COUNT} #{verb} #{url} #{response.code}"
        #     ap payload
        #     ap headers
        #     ap response.time
        #     ap caller
        #     puts response.body
        # end

        create_response extract_real_code( response ), response.body,
                        response.headers['Content-Type']
    end

    def extract_real_code( response )
        # Typhoeus sometimes gets confused when running under JRuby from multiple
        # threads:
        #  https://github.com/typhoeus/typhoeus/issues/411
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
