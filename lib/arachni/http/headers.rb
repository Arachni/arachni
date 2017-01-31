=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'webrick'

module Arachni
module HTTP

# HTTP Headers.
#
# For convenience, Hash-like getters and setters provide case-insensitive access.
#
# @author Tasos Laskos <tasos.laskos@arachni-scanner.com>
class Headers < Hash

    FORMATTED_NAMES_CACHE = Support::Cache::LeastRecentlyPushed.new( 1_000 )

    CONTENT_TYPE = 'content-type'
    SET_COOKIE   = 'set-cookie'
    LOCATION     = 'location'

    # @param  [Headers, Hash] headers
    def initialize( headers = {} )
        merge!( headers || {} )
    end

    def merge!( headers, convert_to_array = true )
        headers.each do |k, v|
            # Handle headers with identical normalized names, like a mixture of
            # Set-Cookie and SET-COOKIE.
            if convert_to_array && include?( k )
                self[k] = [self[k]].flatten
                self[k] << v
            else
                self[k] = v
            end
        end
    end

    def merge( headers, convert_to_array = true )
        d = dup
        d.merge! headers, convert_to_array
        d
    end

    # @note `field` will be capitalized appropriately before storing.
    #
    # @param    [String]  field
    #   Field name
    #
    # @return   [String]
    #   Field value.
    def delete( field )
        super format_field_name( field.to_s.downcase )
    end

    # @note `field` will be capitalized appropriately before storing.
    #
    # @param    [String]  field
    #   Field name
    #
    # @return   [String]
    #   Field value.
    def include?( field )
        super format_field_name( field.to_s.downcase )
    end

    # @note `field` will be capitalized appropriately before storing.
    #
    # @param    [String]  field
    #   Field name
    #
    # @return   [String]
    #   Field value.
    def []( field )
        super format_field_name( field.to_s.downcase ).freeze
    end

    # @note `field` will be capitalized appropriately before storing.
    #
    # @param    [String]  field
    #   Field name
    # @param    [Array<String>, String]  value
    #   Field value.
    #
    # @return   [String]
    #   Field `value`.
    def []=( field, value )
        super format_field_name( field.to_s.downcase ).freeze,
              value.is_a?( Array ) ? value : value.to_s.freeze
    end

    # @return   [String, nil]
    #   Value of the `Content-Type` field.
    def content_type
        (ct = self[CONTENT_TYPE]).is_a?( Array ) ? ct.first : ct
    end

    # @return   [String, nil]
    #   Value of the `Location` field.
    def location
        self[LOCATION]
    end

    # @return   [Array<String>]
    #   Set-cookie strings.
    def set_cookie
        return [] if self[SET_COOKIE].to_s.empty?
        [self[SET_COOKIE]].flatten
    end

    # @return   [Array<Hash>]
    #   Cookies as hashes.
    def cookies
        return [] if set_cookie.empty?

        set_cookie.map do |set_cookie_string|
            WEBrick::Cookie.parse_set_cookies( set_cookie_string ).flatten.uniq.map do |cookie|
                cookie_hash = {}
                cookie.instance_variables.each do |var|
                    cookie_hash[var.to_s.gsub( /@/, '' ).to_sym] = cookie.instance_variable_get( var )
                end

                # Replace the string with a Time object.
                cookie_hash[:expires] = cookie.expires
                cookie_hash
            end
        end.flatten.compact
    end

    private

    def format_field_name( field )
        self.class.format_field_name( field )
    end

    def self.format_field_name( field )
        # If there's a '--' somewhere in there then skip it, it probably is an
        # audit payload.
        return field if field.include?( '--' )

        FORMATTED_NAMES_CACHE.fetch field do
            field.split( '-' ).map( &:capitalize ).join( '-' )
        end
    end

end
end
end
