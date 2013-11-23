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
