=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative 'base'

module Arachni::Element

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class UIInput < Base
    require_relative 'ui_input/dom'

    include Arachni::Element::Capabilities::DOMOnly

    SUPPORTED_TYPES = %w(input textarea)

    def self.type
        :ui_input
    end

    def self.from_browser( browser, page )
        inputs = []

        return inputs if !browser.javascript.supported? || !in_html?( page.body )

        browser.each_element_with_events SUPPORTED_TYPES do |locator, events|
            next if locator.attributes['type'] && locator.attributes['type'] != 'text'

            events.each do |event, _|
                name = locator.attributes['name'] || locator.attributes['id'] ||
                    locator.to_s

                inputs << new(
                    action: page.url,
                    source: locator.to_s,
                    method: event,
                    inputs: {
                        name => locator.attributes['value'].to_s
                    }
                )
            end
        end

        inputs
    end

    def self.in_html?( html )
        with_textarea_in_html?( html ) || with_input_in_html?( html )
    end

    def self.with_textarea_in_html?( html )
        html.has_html_tag?( 'textarea' )
    end

    def self.with_input_in_html?( html )
        html.has_html_tag?( 'input', /text|(?!type=)/ )
    end

end
end

Arachni::UIInput = Arachni::Element::UIInput
