=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class DOM
module Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Submittable
    include Arachni::Element::Capabilities::Submittable

    # @param  [Hash]  options
    # @param  [Block]  block
    #   Callback to be passed the evaluated {Page}.
    def submit( options = {}, &block )
        with_browser do |browser|
            prepare_browser( browser, options )

            # If we've wondered to an out-of-scope resource don't bother calling.
            # Can be caused by a JS redirect or something akin to that.
            if (transitions = self.trigger.compact).any?
                page = browser.to_page
                page.dom.transitions += transitions
                block.call page.tap { |p| p.request.performer = self }
            end

            @element = nil
            @browser = nil
        end
        nil
    end

    private

    def prepare_browser( browser, options )
        @browser = browser
        browser.javascript.custom_code = options[:custom_code]
        browser.javascript.taint       = options[:taint]

        browser.load page
    end

end

end
end
end
