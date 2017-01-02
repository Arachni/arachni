=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

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

    def submit( options = {}, method = nil, &block )
        # Remove references to the Auditor instance (the check instance) to
        # remove references to the associated pages and HTTP responses etc.
        #
        # We don't know how long we'll be waiting in the queue so keeping these
        # objects in memory can result in big leaks -- which is why we're also
        # moving to class-level callbacks, to avoid closures capturing context.

        auditor  = @auditor
        @auditor = nil

        options = options.merge(
            element: self,
            auditor: auditor.class,
            page:    page
        )

        if method
            auditor.with_browser( options, method )
        else
            auditor.with_browser( options, &Submittable.prepare_callback( &block ) )
        end

        nil
    end

    def self.prepare_callback( &block )
        lambda do |browser, options|
            Submittable.prepare_browser( browser, options )
            Submittable.submit_with_browser( browser, options, &block )
        end
    end

    def self.prepare_browser( browser, options )
        browser.javascript.custom_code = options[:custom_code]
        browser.javascript.taint       = options[:taint]
        browser.load options[:page]
    end

    def self.submit_with_browser( browser, options, &cb )
        element = options[:element]
        element.browser = browser
        element.auditor = options[:auditor]
        element.page    = options[:page]

        # If we've wandered to an out-of-scope resource don't bother calling.
        # Can be caused by a JS redirect or something akin to that.
        if (transitions = element.trigger.compact).any?
            page = browser.to_page
            page.dom.transitions  += transitions
            page.request.performer = element

            # Auditable.handle_submission_result page
            cb.call( page ) if block_given?
            return page
        end

        nil
    end

end

end
end
end
