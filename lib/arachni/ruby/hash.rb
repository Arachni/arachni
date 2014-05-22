=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Hash

    # Converts the hash keys to strings.
    #
    # @param    [Boolean]    recursively    Go through the Hash recursively?
    #
    # @return [Hash]
    #   Hash with +self+'s keys recursively converted to strings.
    def stringify_keys( recursively = true )
        stringified = {}
        each do |k, v|
            stringified[k.to_s] = (recursively && v.is_a?( Hash ) ? v.stringify_keys : v)
        end
        stringified
    end

    # Converts the hash keys to symbols.
    #
    # @param    [Boolean]    recursively    Go through the Hash recursively?
    #
    # @return [Hash]
    #   Hash with +self+'s keys recursively converted to symbols.
    def symbolize_keys( recursively = true )
        symbolize = {}
        each do |k, v|
            k = k.respond_to?(:to_sym) ? k.to_sym : k

            symbolize[k] = (recursively && v.is_a?( Hash ) ?
                v.symbolize_keys : v)
        end
        symbolize
    end

    # @return [Hash]
    #   Hash with +self+'s keys and values recursively converted to strings.
    def stringify
        apply_recursively(:to_s)
    end

    def stringify_recursively_and_freeze
        modified = {}

        each do |k, v|
            if v.is_a?( Hash )
                modified[k.to_s.freeze] = v.stringify_recursively_and_freeze
            else
                modified[k.to_s.freeze] = v.to_s.freeze
            end
        end

        modified.freeze
    end

    def apply( method, *args )
        modified = {}

        each do |k, v|
            if v.is_a?( Hash )
                modified[k.send(method, *args)] = v
            else
                modified[k.send(method, *args)] = v.send(method, *args)
            end
        end

        modified
    end

    def apply_recursively( method, *args )
        modified = {}

        each do |k, v|
            modified[k.send(method, *args)] = v.is_a?( Hash ) ?
                v.apply_recursively(method, *args) : v.send(method, *args)
        end

        modified
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

    # Recursively converts the hash's string data to UTF8.
    #
    # @return [Hash]
    #   Copy of `self` with all strings {String#recode recoded} to UTF8.
    def recode
        recoded = {}
        each do |k, v|
            recoded[k] = (v.respond_to?( :recode ) ? v.recode : v)
        end
        recoded
    end

    # @return   [Array<Symbol>]
    #   Returns all symbol keys from +self+ and children hashes.
    def find_symbol_keys_recursively
        flat = []
        each do |k, v|
            flat << k
            flat |= v.find_symbol_keys_recursively if v.is_a?( Hash ) &&v.any?
        end
        flat.reject { |i| !i.is_a? Symbol }
    end

end
