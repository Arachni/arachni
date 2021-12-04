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

            timeout:        Arachni::Options.browser_cluster.job_timeout,

            nosignal:       true,

            # Small trick to cancel out http_proxy env variables which would
            # otherwise be honoured by libcurl and hinder browser communications.
            proxy:          ''
        }

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

        create_response response.code, response.body, response.headers['Content-Type']
    end

end

end
end
end
end
