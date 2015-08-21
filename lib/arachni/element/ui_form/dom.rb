=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class UIForm

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class DOM < Base
    include Arachni::Element::Capabilities::WithNode
    include Arachni::Element::Capabilities::Auditable::DOM

    INPUTS = Set.new([:input, :textarea])

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
        transitions = fill_in_inputs

        main_transition = browser.fire_event( element, @method, value: value )
        return if !main_transition

        transitions + [main_transition]
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

    def type
        self.class.type
    end
    def self.type
        :ui_form_dom
    end

    def initialization_options
        super.merge( inputs: inputs.dup, method: @method )
    end

    private

    def fill_in_inputs
        transitions = []

        INPUTS.each do |tag|
            next if !page.has_elements?( tag )

            browser.watir.send("#{tag}s").each do |locator|
                attrs = Arachni::Browser::ElementLocator.
                    from_html( locator.opening_tag ).attributes

                next if attrs['type'] && attrs['type'] != 'text'

                print_status "Filling in '#{locator.opening_tag}'"

                transitions << fill_in_input( browser, locator )
            end
        end

        transitions
    end

    def fill_in_input( browser, locator )
        browser.fire_event( locator, :input, value: value )
    end

end
end
end
