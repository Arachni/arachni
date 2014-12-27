=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class Form

# Provides access to DOM operations for {Form forms}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class DOM < Base
    include Capabilities::Auditable::DOM

    def initialize( options )
        super

        inputs = (options[:inputs] || self.parent.inputs).dup
        @valid_input_names = inputs.keys.map(&:to_s)

        self.inputs     = inputs
        @default_inputs = self.inputs.dup.freeze
    end

    # Submits the form using the configured {#inputs}.
    def trigger
        browser.fire_event element, :submit, inputs: inputs.dup
    end

    def valid_input_name?( name )
        @valid_input_names.include? name.to_s
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
