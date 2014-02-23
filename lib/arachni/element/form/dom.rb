=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni::Element
class Form

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class DOM < Capabilities::Auditable::DOM

    def initialize(*)
        super

        self.inputs     = self.parent.inputs.dup
        @default_inputs = self.inputs.dup.freeze
    end

    def locate
        # TODO: Also use input names to be sure.
        browser.watir.form( valid_attributes )
    end

    def trigger
        browser.fire_event element, :onsubmit, inputs: inputs.dup
    end

end

end
end
