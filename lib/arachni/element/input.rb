=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Input < Base
    require_relative 'input/dom'

    include Arachni::Element::Capabilities::DOMOnly

    SUPPORTED_TYPES = Set.new([:input, :textarea])

    def self.type
        :input
    end

    def self.from_browser( browser, page )
        inputs = []

        return inputs if !browser.javascript.supported?

        if page.document.css( 'textarea' ).empty? &&
            page.document.xpath( '//input[@type="text"]' ).empty? &&
                page.document.xpath( '//input[not(@type)]' ).empty?
            return inputs
        end

        browser.each_element_with_events false do |locator, events|
            next if !SUPPORTED_TYPES.include?( locator.tag_name )
            next if locator.attributes['type'] &&
                locator.attributes['type'] != 'text'

            browser.filter_events( locator.tag_name, events ).each do |event, _|
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

end
end

Arachni::Input = Arachni::Element::Input
