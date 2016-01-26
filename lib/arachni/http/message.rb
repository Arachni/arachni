=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module HTTP

# @author Tasos Laskos <tasos.laskos@arachni-scanner.com>
class Message
    require_relative 'message/scope'

    # @return   [String]
    #   Resource location.
    attr_accessor :url

    # @return   [Headers<String, String>]
    #   HTTP headers as a Hash-like object.
    attr_accessor :headers

    # @return   [String]
    #   {Request}/{Response} body.
    attr_accessor :body

    # @note All options will be sent through the class setters whenever
    #   possible to allow for normalization.
    #
    # @param    [Hash]  options
    #   Message options.
    # @option   options [String]    :url
    #   URL.
    # @option   options [Hash]      :headers
    #   HTTP headers.
    # @option   options [String]    :body
    #   Body.
    def initialize( options = {} )
        options = options.dup

        @normalize_url = options.delete( :normalize_url )
        @normalize_url = true if @normalize_url.nil?

        # Headers are necessary for subsequent operations to set them first.
        @headers = Headers.new( options.delete( :headers ) || {} )

        options.each do |k, v|
            begin
                send( "#{k}=", v )
            rescue NoMethodError
                instance_variable_set( "@#{k}".to_sym, v )
            end
        end

        fail ArgumentError, 'Missing :url.' if url.to_s.empty?
    end

    def headers=( h )
        @headers = Headers.new( h || {} )
    end

    # @return   [Scope]
    def scope
        @scope ||= self.class::Scope.new( self )
    end

    def parsed_url
        # Don't cache this, that's already handled by the URI parser's own cache.
        Arachni::URI( url )
    end

    def url=( url )
        if @normalize_url
            @url = URI.normalize_url( url ).to_s.freeze
        else
            @url = url.to_s.freeze
        end
    end

end
end
end
