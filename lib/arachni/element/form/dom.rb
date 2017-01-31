=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative '../dom'

module Arachni::Element
class Form

# Extends {Arachni::Element::Capabilities::Auditable::DOM} with {Form}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class DOM < DOM
    include Arachni::Element::Capabilities::WithNode

    include Arachni::Element::DOM::Capabilities::Locatable
    include Arachni::Element::DOM::Capabilities::Mutable
    include Arachni::Element::DOM::Capabilities::Inputtable
    include Arachni::Element::DOM::Capabilities::Submittable
    include Arachni::Element::DOM::Capabilities::Auditable

    def initialize( options )
        super

        inputs = (options[:inputs] || self.parent.inputs).dup
        @valid_input_names = inputs.keys.map(&:to_s)

        self.inputs     = inputs
        @default_inputs = self.inputs.dup.freeze
    end

    # Submits the form using the configured {#inputs}.
    def trigger
        [ browser.fire_event( locate, :submit, inputs: inputs.dup ) ]
    end

    def valid_input_name?( name )
        @valid_input_names.include? name.to_s
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
