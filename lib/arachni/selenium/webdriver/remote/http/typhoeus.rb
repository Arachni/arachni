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
            followlocation: true
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
        create_response response.code, response.body, response.headers['Content-Type']
    end

end

end
end
end
end
