=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Hash

    #
    # Converts the hash keys to strings.
    #
    # @param    [Boolean]    recursively    Go through the Hash recursively?
    #
    # @return [Hash]
    #   Hash with +self+'s keys recursively converted to strings.
    #
    def stringify_keys( recursively = true )
        stringified = {}
        each do |k, v|
            stringified[k.to_s] = (recursively && v.is_a?( Hash ) ? v.stringify_keys : v)
        end
        stringified
    end

    #
    # Converts the hash keys to symbols.
    #
    # @param    [Boolean]    recursively    Go through the Hash recursively?
    #
    # @return [Hash]
    #   Hash with +self+'s keys recursively converted to symbols.
    #
    def symbolize_keys( recursively = true )
        symbolize = {}
        each do |k, v|
            symbolize[k.to_s.to_sym] = (recursively && v.is_a?( Hash ) ? v.symbolize_keys : v)
        end
        symbolize
    end

    # @return   [Hash]
    #   Self with the keys and values converted to lower-case strings.
    def downcase
        stringify_keys.inject({}) do |h, (k, v)|
            k = k.downcase if k.is_a?( String )
            v = v.downcase if v.is_a?( String )
            h[k] = v
            h
        end
    end

end
