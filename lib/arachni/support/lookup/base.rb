=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

require 'set'

module Arachni
module Support::LookUp

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @abstract
class Base

    attr_reader :collection

    DEFAULT_OPTIONS = {
        hasher: :hash
    }

    # @param    [Hash]  options
    # @option   options [Symbol]    (:hasher)
    #   Method to call on the item to obtain its hash.
    def initialize( options = {} )
        @options = DEFAULT_OPTIONS.merge( options )
        @hasher  = @options[:hasher].to_sym
    end

    # @param    [#persistent_hash] item
    #   Item to insert.
    #
    # @return   [HashSet]
    #   `self`
    def <<( item )
        @collection << calculate_hash( item )
        self
    end
    alias :add :<<

    # @param    [#persistent_hash] item
    #   Item to delete.
    #
    # @return   [HashSet]
    #   `self`
    def delete( item )
        @collection.delete( calculate_hash( item ) )
        self
    end

    # @param    [#persistent_hash] item
    #   Item to check.
    #
    # @return   [Bool]
    def include?( item )
        @collection.include? calculate_hash( item )
    end

    def empty?
        @collection.empty?
    end

    def any?
        !empty?
    end

    def size
        @collection.size
    end

    def clear
        @collection.clear
    end

    def ==( other )
        hash == other.hash
    end

    def hash
        @collection.hash
    end

    def dup
        deep_clone
    end

    private

    def calculate_hash( item )
        item.send @hasher
    end

end

end
end
