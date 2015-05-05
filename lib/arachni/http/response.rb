=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module HTTP

# HTTP Response representation.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Response < Message
    require_relative 'response/scope'

    # @return   [Integer]
    #   HTTP response status code.
    attr_accessor :code

    # @return   [String]
    #   IP address of the server.
    attr_accessor :ip_address

    # @return   [String]
    #   HTTP response status message.
    attr_accessor :message

    # @return   [Request]
    #   HTTP {Request} which triggered this {Response}.
    attr_accessor :request

    # @return   [Array<Response>]
    #   Automatically followed redirections that eventually led to this response.
    attr_accessor :redirections

    # @return   [Symbol]
    #   `libcurl` return code.
    attr_accessor :return_code

    # @return   [String]
    #   `libcurl` return code.
    attr_accessor :return_message

    # @return   [String]
    #   Raw headers.
    attr_accessor :headers_string

    # @return   [Float]
    #   Total time in seconds for the transfer, including name resolving, TCP
    #   connect etc.
    attr_accessor :total_time

    # @return   [Float]
    #   Time, in seconds, it took from the start until the full response was
    #   received.
    attr_accessor :time

    # @return   [Float]
    #   Approximate time the web application took to process the {#request}.
    attr_accessor :app_time

    def initialize( options = {} )
        super( options )

        @body ||= ''
        @code ||= 0

        # Holds the redirection responses that eventually led to this one.
        @redirections ||= []

        @time ||= 0.0
    end

    def time=( t )
        @time = t.to_f
    end

    # @return   [Platform]
    #   Applicable platforms for the page.
    def platforms
        Platform::Manager[url]
    end

    # @return   [String]
    #   First line of the response.
    def status_line
        return if !headers_string
        @status_line ||= headers_string.lines.first.to_s.chomp.freeze
    end

    # @return   [String]
    #   HTTP response string.
    def to_s
        "#{headers_string}#{body}"
    end

    # @return [Boolean]
    #   `true` if the response is a `3xx` redirect **and** there is a `Location`
    #   header field.
    def redirect?
        code >= 300 && code <= 399 && !!headers.location
    end
    alias :redirection? :redirect?

    def headers_string=( string )
        @headers_string = string.freeze
    end

    # @note Depends on the response code.
    #
    # @return [Boolean]
    #   `true` if the remote resource has been modified since the date given in
    #   the `If-Modified-Since` request header field, `false` otherwise.
    def modified?
        code != 304
    end

    # @return [Bool]
    #   `true` if the response body is textual in nature, `false` if binary,
    #   `nil` if could not be determined.
    def text?
        return if !@body

        if (type = headers.content_type)
            return true if type.start_with?( 'text/' )

            # Non "text/" nor "application/" content types will surely not be
            # text-based so bail out early.
            return false if !type.start_with?( 'application/' )
        end

        # Last resort, more resource intensive binary detection.
        begin
            !@body.binary?
        rescue ArgumentError
            nil
        end
    end

    # @return   [Boolean]
    #   `true` if timed out, `false` otherwise.
    def timed_out?
        [:operation_timedout, :couldnt_connect].include? return_code
    end

    def body=( body )
        @body = body.to_s.dup

        text_check = text?
        @body.recode! if text_check.nil? || text_check

        @body.freeze
    end

    # @return [Arachni::Page]
    def to_page
        Page.from_response self
    end

    # @return   [Hash]
    def to_h
        hash = {}
        instance_variables.each do |var|
            hash[var.to_s.gsub( /@/, '' ).to_sym] = instance_variable_get( var )
        end

        hash[:headers] = {}.merge( hash[:headers] )

        hash.delete( :scope )
        hash.delete( :parsed_url )
        hash.delete( :redirections )
        hash.delete( :request )
        hash.delete( :scope )

        hash
    end

    # @return   [Hash]
    #   Data representing this instance that are suitable the RPC transmission.
    def to_rpc_data
        data = to_h
        data[:request] = request.to_rpc_data
        data.my_stringify_keys(false)
    end

    # @param    [Hash]  data    {#to_rpc_data}
    # @return   [Request]
    def self.from_rpc_data( data )
        data['request']     = Request.from_rpc_data( data['request'] )
        data['return_code'] = data['return_code'].to_sym if data['return_code']
        new data
    end

    def ==( other )
        hash == other.hash
    end

    def hash
        to_h.hash
    end

    def self.from_typhoeus( response )
        redirections = response.redirections.map do |redirect|
            rurl   = URI.to_absolute( redirect.headers['Location'],
                                      response.effective_url )
            rurl ||= response.effective_url

            # Broken redirection, skip it...
            next if !rurl

            new(
                url:     rurl,
                code:    redirect.code,
                headers: redirect.headers
            )
        end

        new(
            url:            response.effective_url,
            code:           response.code,
            ip_address:     response.primary_ip,
            headers:        response.headers,
            headers_string: response.response_headers,
            body:           response.body,
            redirections:   redirections,
            time:           response.time,
            app_time:       (response.timed_out? ? response.time :
                                response.start_transfer_time - response.pretransfer_time).to_f,
            total_time:     response.total_time.to_f,
            return_code:    response.return_code,
            return_message: response.return_message
        )
    end

end
end
end
