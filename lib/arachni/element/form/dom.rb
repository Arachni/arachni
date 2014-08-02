=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni::Element
class Form

# Provides access to DOM operations for {Form forms}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class DOM < Base
    include Capabilities::Auditable::DOM

    def initialize( options )
        super

        self.inputs     = (options[:inputs] || self.parent.inputs).dup
        @default_inputs = self.inputs.dup.freeze
    end

    # Submits the form using the configured {#inputs}.
    def trigger
        browser.fire_event element, :submit, inputs: inputs.dup
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

    def initialization_options
        super.merge( inputs: inputs.dup )
    end

end

end
end
