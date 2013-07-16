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
class Message

    # @return   [String]    Resource location.
    attr_reader :url

    # @return [Arachni::URI]  Parsed version of {#url}.
    attr_reader :parsed_url

    # @return [String]  HTTP version.
    attr_reader :version

    # @return [Headers<String, String>]  HTTP headers as a Hash-like object.
    attr_reader :headers

    # @return [String]  {Request}/{Response} body.
    attr_reader :body

    # @note All options will be sent through the class setters whenever
    #   possible to allow for normalization.
    #
    # @param  [Hash]  options Message options.
    # @option options [Hash] :headers HTTP headers.
    # @option options [String] :body Body.
    # @option options [String] :version (1.1) HTTP version.
    def initialize( url, options = {} )
        if url.is_a?( Hash )
            options = url
        else
            options[:url] = url
        end

        options.each do |k, v|
            v = my_dup( v )
            begin
                send( "#{k}=", v )
            rescue NoMethodError
                instance_variable_set( "@#{k}".to_sym, v )
            end
        end

        @headers  = Headers.new( @headers )
        @version ||= '1.1'
    end

    def url=( uri )
        @url        = uri.to_s
        @parsed_url = Arachni::URI( @url )
        @url
    end

    private

    def my_dup( value )
        value.dup rescue value
    end

end
end
end
