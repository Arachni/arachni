=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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

module Typhoeus
class Response

    def content_type
        return if !headers_hash.is_a?( Hash )

        headers_hash.each_pair do |key, val|
            return val if key.to_s.downcase == 'content-type'
        end

        return
    end

    def redirection?
        (300..399).include?( @code )
    end

    #
    # Converts obj to hash
    #
    # @return    [Hash]
    #
    def to_hash
        hash = {}
        instance_variables.each do |var|
            hash[var.to_s.gsub( /@/, '' )] = instance_variable_get( var )
        end

        hash['headers_hash'] = {}
        headers_hash.each_pair { |k, v| hash['headers_hash'][k] = v }

        hash.delete( 'request' )
        hash
    end
end
end
