=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Enum option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @abstract
class Arachni::Component::Options::Enum < Arachni::Component::Options::Base

    # The list of potential valid values
    attr_accessor :valid_values

    def initialize( name, options = {} )
        options = options.dup
        @valid_values = [options.delete(:valid_values)].flatten.compact.map(&:to_s)
        super
    end

    def valid?
        return false if !super
        valid_values.include?( value )
    end

    def description
        "#{@description} (accepted: #{valid_values.join( ', ' )})"
    end

    def type
        'enum'
    end

end
