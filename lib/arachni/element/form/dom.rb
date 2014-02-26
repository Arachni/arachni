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

    def initialize( options )
        super

        self.inputs     = (options[:inputs] || self.parent.inputs).dup
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

    def encode( *args )
        Form.encode( *args )
    end

    def decode( *args )
        Form.decode( *args )
    end

    def type
        self.class.type
    end
    def self.type
        :form_dom
    end

    def watir_type
        self.class.watir_type
    end

    def self.watir_type
        :form
    end

    def self.unserialize_node( *args )
        Form.unserialize_node( *args )
    end

    private

    def dup_options
        super.merge( inputs: inputs.dup )
    end

end

end
end
