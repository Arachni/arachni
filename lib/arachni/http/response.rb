=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

module Arachni
module HTTP

# HTTP Response representation.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Response < Message

    # @return [Integer] HTTP response status code.
    attr_accessor :code

    # @return [String] IP address of the server.
    attr_accessor :ip_address

    # @return [String] HTTP response status message.
    attr_accessor :message

    # @return [Request] HTTP {Request} which triggered this {Response}.
    attr_accessor :request

    # @return [Array<Response>]
    #   Automatically followed redirections that eventually led to this response.
    attr_accessor :redirections

    # @return   [Symbol]    `libcurl` return code.
    attr_accessor :return_code

    # @return [String]  `libcurl` return code.
    attr_accessor :return_message

    # @return   [String]    Raw headers.
    attr_accessor :headers_string

    # @return   [Float]
    #   Total time in seconds for the transfer, including name resolving, TCP
    #   connect etc.
    attr_accessor :total_time

    # @return   [Float]
    #   Time, in seconds, it took from the start until the first byte was
    #   received
    attr_accessor :time

    def initialize( *args )
        super( *args )

        @body ||= ''
        @body   = @body.recode if text?
        @code ||= 0

        # Holds the redirection responses that eventually led to this one.
        @redirections ||= []
    end

    # @return [Boolean]
    #   `true` if the response is a `3xx` redirect **and** there is a `Location`
    #   header field.
    def redirect?
        code >= 300 && code <= 399 && !!headers.location
    end
    alias :redirection? :redirect?

    # @note Depends on the response code.
    #
    # @return [Boolean]
    #   `true` if the remote resource has been modified since the date given in
    #   the `If-Modified-Since` request header field, `false` otherwise.
    def modified?
        code != 304
    end

    # @return [Bool]
    #   `true` if the response body is textual in nature, `false` otherwise
    #   (if binary).
    def text?
        return if !@body

        if (type = headers.content_type)
            return true if type.start_with?( 'text/' )

            # Non "application/" content types will surely not be text-based
            # so bail out early.
            return false if !type.start_with?( 'application/' )
        end

        # Last resort, more resource intensive binary detection.
        !@body.binary?
    end

    # @return [Boolean] `true` if timed out, `false` otherwise.
    def timed_out?
        [:operation_timedout, :couldnt_connect].include? return_code
    end

    # @return [Arachni::Page]
    def to_page
        Page.from_response self
    end

    # @return   [Hash]
    def to_h
        hash = {}
        instance_variables.each do |var|
            hash[var.to_s.gsub( /@/, '' )] = instance_variable_get( var )
        end

        hash['headers'] = {}.merge( hash['headers'] )

        hash.delete( 'parsed_url' )
        hash.delete( 'redirections' )
        hash.delete( 'request' )
        hash
    end

    def ==( other )
        hash == other.hash
    end

    def hash
        to_h.hash
    end

    def self.from_typhoeus( response )
        redirections = response.redirections.
            map { |r| new( code: r.code, headers: r.headers ) }

        new(
            url:            response.effective_url,
            code:           response.code,
            ip_address:     response.primary_ip,
            headers:        response.headers,
            headers_string: response.response_headers,
            body:           response.body,
            redirections:   redirections,
            time:           response.starttransfer_time,
            total_time:     response.total_time,
            return_code:    response.return_code,
            return_message: response.return_message
        )
    end

end
end
end
