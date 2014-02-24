=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni::Element
class Form

# Provides access to DOM operations for {Form forms}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class DOM < Capabilities::Auditable::DOM

    def initialize(*)
        super

        self.inputs     = self.parent.inputs.dup
        @default_inputs = self.inputs.dup.freeze
    end

    # @return   [Watir::Form]
    def locate
        # TODO: Also use input names to be sure.
        browser.watir.form( valid_attributes )
    end

    # Submits the form using the configured {#inputs}.
    def trigger
        browser.fire_event element, :onsubmit, inputs: inputs.dup
    end

end

end
end
