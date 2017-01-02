=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative '../dom'

module Arachni::Element
class UIForm

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class DOM < DOM
    include Arachni::Element::Capabilities::WithNode

    include Arachni::Element::DOM::Capabilities::Locatable
    include Arachni::Element::DOM::Capabilities::Mutable
    include Arachni::Element::DOM::Capabilities::Inputtable
    include Arachni::Element::DOM::Capabilities::Submittable
    include Arachni::Element::DOM::Capabilities::Auditable

    INPUTS = Set.new([:input, :textarea])

    def initialize( options )
        super

        @opening_tags = (options[:opening_tags] || parent.opening_tags).dup

        self.method = options[:method] || self.parent.method

        inputs = (options[:inputs] || self.parent.inputs ).dup

        @valid_input_names = Set.new(inputs.keys)
        self.inputs        = inputs

        @default_inputs = self.inputs.dup.freeze
    end

    # Submits the form using the configured {#inputs}.
    def trigger
        transitions = fill_in_inputs

        print_debug "Submitting: #{self.source}"
        submission_transition = browser.fire_event( locate, @method )
        print_debug "Submitted: #{self.source}"

        return [] if !submission_transition

        transitions + [submission_transition]
    end

    def valid_input_name?( name )
        @valid_input_names.include? name.to_s
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
        :ui_form_dom
    end

    def initialization_options
        super.merge(
            inputs:       inputs.dup,
            method:       @method,
            opening_tags: @opening_tags.dup
        )
    end

    def marshal_dump
        super.tap { |h| h.delete :@valid_input_names }
    end

    private

    def fill_in_inputs
        transitions = []

        @inputs.each do |name, value|
            locator     = locator_for_input( name )
            opening_tag = @opening_tags[name]

            print_debug "Filling in: #{name} => #{value} [#{opening_tag}]"

            t = browser.fire_event( locator, :input, value: value )

            if !t
                print_debug "Could not fill in: #{name} => #{value} [#{opening_tag}]"
                next
            end
            print_debug "Filled in: #{name} => #{value} [#{opening_tag}]"

            transitions << t
        end

        transitions
    end

    def locator_for_input( name )
        Arachni::Browser::ElementLocator.from_html @opening_tags[name]
    end

end
end
end
