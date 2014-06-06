=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module HTTP

# @author Tasos Laskos <tasos.laskos@gmail.com>
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
        options.each do |k, v|
            v = my_dup( v )
            begin
                send( "#{k}=", v )
            rescue NoMethodError
                instance_variable_set( "@#{k}".to_sym, v )
            end
        end

        fail ArgumentError, 'Missing :url.' if url.to_s.empty?

        @headers = Headers.new( @headers )
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
        @url = Arachni::URI( url ).to_s.freeze
    end

    private

    def my_dup( value )
        value.dup rescue value
    end

end
end
end
