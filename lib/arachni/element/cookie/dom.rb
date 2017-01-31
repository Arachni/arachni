=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative '../dom'

module Arachni::Element
class Cookie

# Provides access to DOM operations for {Cookie cookies}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class DOM < DOM
    include Arachni::Element::DOM::Capabilities::Mutable
    include Arachni::Element::DOM::Capabilities::Inputtable
    include Arachni::Element::DOM::Capabilities::Submittable
    include Arachni::Element::DOM::Capabilities::Auditable

    def initialize( options )
        super

        self.inputs     = (options[:inputs] || self.parent.inputs).dup
        @default_inputs = self.inputs.dup.freeze
    end

    # Submits the cookie using the configured {#inputs}.
    def trigger
        [ browser.goto(
            action,
            take_snapshot:      false,
            cookies:            self.inputs,
            update_transitions: false
        ) ]
    end

    def name
        inputs.keys.first
    end

    def value
        inputs.values.first
    end

    def to_set_cookie
        p = parent.dup
        p.inputs = inputs
        p.to_set_cookie
    end

    def type
        self.class.type
    end
    def self.type
        :cookie_dom
    end

    def initialization_options
        super.merge( inputs: inputs.dup )
    end

end

end
end
