=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
module WithDOM
    include WithNode

    # @return     [DOM]
    attr_accessor :dom

    # @return   [DOM]
    def dom
        @dom ||= self.class::DOM.new( parent: self )
    end

    def dup
        copy_with_dom( super )
    end

    def hash
        "#{super}:#{dom.hash}".hash
    end

    private

    def copy_with_dom( other )
        other.dom = dom.dup.tap { |d| d.parent = other } if @dom
        other
    end

end

end
end
