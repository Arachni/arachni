=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class UIInput < Base
    require_relative 'input/dom'

    include Arachni::Element::Capabilities::DOMOnly

    SUPPORTED_TYPES = Set.new([:input, :textarea])

    def self.type
        :ui_input
    end

    def self.from_browser( browser, page )
        inputs = []

        return inputs if !browser.javascript.supported?

        body = page.body
        if !(body.has_html_tag?( 'textarea' ) ||
            body.has_html_tag?( 'input', 'text' ) ||
            body.has_html_tag?( 'input', /(?!type=)/))
            return inputs
        end

        if !page.has_elements?( 'textarea' ) &&
            page.document.xpath( '//input[@type="text"]' ).empty? &&
            page.document.xpath( '//input[not(@type)]' ).empty?
            return inputs
        end

        browser.elements_with_events.each do |locator, events|
            next if !SUPPORTED_TYPES.include?( locator.tag_name )
            next if locator.attributes['type'] &&
                locator.attributes['type'] != 'text'

            browser.javascript.class.select_events( locator.tag_name, events ).each do |event, _|
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
        html.has_html_tag?( 'input', 'text' ) ||
            html.has_html_tag?( 'input', /(?!type=)/)
    end

end
end

Arachni::UIInput = Arachni::Element::UIInput
