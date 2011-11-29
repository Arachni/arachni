
module Typhoeus
  class Response

    #
    # Converts obj to hash
    #
    # @param    [Object]  obj    instance of an object
    #
    # @return    [Hash]
    #
    def to_hash
        hash = Hash.new
        instance_variables.each {
            |var|
            key       = var.to_s.gsub( /@/, '' )
            hash[key] = instance_variable_get( var )

        }

        hash['headers_hash'] = {}
        headers_hash.each_pair {
            |k, v|
            hash['headers_hash'][k] = v
        }

        hash.delete( 'request' )

        return hash
    end


  end
end
