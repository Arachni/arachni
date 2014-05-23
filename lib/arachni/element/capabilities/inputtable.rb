=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Element

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module Capabilities::Inputtable

    # Frozen version of {#inputs}, has all the original name/values.
    #
    # @return   [Hash]
    attr_reader :default_inputs

    # Frozen inputs.
    #
    # If you want to change it you'll either have to use {#update} or the
    # {#inputs=} attr_writer and pass a new hash -- the new hash will also be
    # frozen.
    #
    # @return   [Hash]
    attr_reader :inputs

    # @param  [Hash]  hash Inputs/params.
    #
    # @note Will convert keys and values to strings.
    #
    # @see #inputs
    def inputs=( hash )
        @inputs = (hash || {}).stringify_recursively_and_freeze
    end

    # Checks whether or not the given inputs match the inputs ones.
    #
    # @param    [Hash, Array, String, Symbol]   args
    #   Names of inputs to check (also accepts var-args).
    #
    # @return   [Bool]
    def has_inputs?( *args )
        if (h = args.first).is_a?( Hash )
            h.each { |k, v| return false if self[k] != v }
            true
        else
            keys = args.flatten.compact.map { |a| [a].map( &:to_s ) }.flatten
            (self.inputs.keys & keys).size == keys.size
        end
    end

    # @param    [Hash]  hash
    #   Inputs with which to update the {#inputs} inputs.
    #
    # @return   [Auditable]   self
    #
    # @see #inputs
    # @see #inputs=
    def update( hash )
        self.inputs = self.inputs.merge( hash )
        self
    end

    # @return   [Hash]  Returns changes make to the {#inputs}'s inputs.
    def changes
        (self.default_inputs.keys | self.inputs.keys).inject( {} ) do |h, k|
            if self.default_inputs[k] != self.inputs[k]
                h[k] = self.inputs[k]
            end
            h
        end
    end

    # Resets the inputs to their original format/values.
    def reset
        super if defined?( super )
        self.inputs = @default_inputs.dup
        self
    end

    # Shorthand {#inputs} reader.
    #
    # @param    [#to_s] k   key
    #
    # @return   [String]
    def []( k )
        self.inputs[k.to_s]
    end

    # Shorthand {#inputs} writer.
    #
    # @param    [#to_s] k   key
    # @param    [#to_s] v   value
    #
    # @see #update
    def []=( k, v )
        update( { k.to_s => v } )
        self[k]
    end

    def dup
        copy_inputtable( super )
    end

    def to_h
        (defined?( super ) ? super : {}).merge(
            inputs:         inputs,
            default_inputs: default_inputs
        )
    end

    private

    def copy_inputtable( other )
        other.inputs = self.inputs.dup
        other
    end

end

end
end
