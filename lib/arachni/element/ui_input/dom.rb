=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative '../dom'

module Arachni::Element
class UIInput

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

        self.method = options[:method] || self.parent.method

        if options[:inputs]
            @valid_input_name = options[:inputs].keys.first.to_s
            self.inputs       = options[:inputs]
        else
            @valid_input_name = (locator.attributes['name'] || locator.attributes['id']).to_s
            self.inputs       = {
                @valid_input_name => locator.attributes['value']
            }
        end

        @default_inputs = self.inputs.dup.freeze
    end

    # Submits the form using the configured {#inputs}.
    def trigger
        [ browser.fire_event( locate, @method, value: value ) ]
    end

    def name
        inputs.keys.first
    end

    def value
        inputs.values.first
    end

    def valid_input_name?( name )
        @valid_input_name == name.to_s
    end

    def coverage_id
        "#{super}:#{@method}:#{locator}"
    end

    def id
        "#{super}:#{@method}:#{locator}"
    end

    def type
        self.class.type
    end
    def self.type
        :ui_input_dom
    end

    def initialization_options
        super.merge( inputs: inputs.dup, method: @method )
    end

end
end
end
