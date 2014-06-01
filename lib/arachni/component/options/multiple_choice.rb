=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# MultipleChoice option.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Arachni::Component::Options::MultipleChoice < Arachni::Component::Options::Base

    # The list of potential valid values
    attr_accessor :choices

    def initialize( name, options = {} )
        options  = options.dup
        @choices = [options.delete(:choices)].flatten.compact.map(&:to_s)
        super
    end

    def normalize
        super.to_s
    end

    def valid?
        return false if !super
        choices.include?( effective_value )
    end

    def description
        "#{@description} (accepted: #{choices.join( ', ' )})"
    end

    def type
        :multiple_choice
    end

end
