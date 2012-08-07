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

    alias :old_headers_hash :headers_hash
    def headers_hash
        old_headers_hash
    rescue
        {}
    end

    def []( k )
        find_header_value( k )
    end

    def []=( k, v )
        headers_hash[find_header_field( k ) || k] = v
    end

    def each( &block )
        headers_hash.each( &block )
    end

    def content_type
        find_header_value( 'content-type' )
    end

    def location
        find_header_value( 'location' )
    end

    def redirection?
        (300..399).include?( @code ) || !location.nil?
    end

    # @return    [Hash]   converts self to hash
    def to_hash
        hash = {}
        instance_variables.each do |var|
            hash[var.to_s.gsub( /@/, '' )] = instance_variable_get( var )
        end

        hash['headers_hash'] = {}
        headers_hash.to_hash.each_pair { |k, v| hash['headers_hash'][k] = v }

        hash.delete( 'request' )
        hash
    end

    private
    def find_header_value( field )
        return if !headers_hash.is_a?( Hash ) || headers_hash[field].empty?
        headers_hash.to_hash.each { |k, v| return v if k.downcase == field.downcase }
        nil
    end

    def find_header_field( field )
        return if !headers_hash.is_a?( Hash ) || headers_hash[field].empty?
        headers_hash.to_hash.each { |k, v| return k if k.downcase == field.downcase }
        nil
    end

end
end
