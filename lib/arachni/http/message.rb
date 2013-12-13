=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module HTTP
class Message

    # @return   [String]    Resource location.
    attr_accessor :url

    # @return [Arachni::URI]  Parsed version of {#url}.
    attr_reader :parsed_url

    # @return [String]  HTTP version.
    attr_accessor :version

    # @return [Headers<String, String>]  HTTP headers as a Hash-like object.
    attr_accessor :headers

    # @return [String]  {Request}/{Response} body.
    attr_accessor :body

    # @note All options will be sent through the class setters whenever
    #   possible to allow for normalization.
    #
    # @param  [Hash]  options Message options.
    # @option options [String] :url URL.
    # @option options [Hash] :headers HTTP headers.
    # @option options [String] :body Body.
    # @option options [String] :version (1.1) HTTP version.
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

        @headers  = Headers.new( @headers )
        @version ||= '1.1'
    end

    def url=( url )
        @parsed_url = Arachni::URI( url )
        @url        = @parsed_url.to_s
    end

    private

    def my_dup( value )
        value.dup rescue value
    end

end
end
end
