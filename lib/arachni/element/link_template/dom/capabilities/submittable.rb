=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class LinkTemplate::DOM
module Capabilities

# Extends {Arachni::Element::DOM::Capabilities::Submittable} with
# {LinkTemplate}-specific functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Submittable
    include Arachni::Element::DOM::Capabilities::Submittable

    def prepare_browser( browser, options )
        @browser = browser
        browser.javascript.custom_code = options[:custom_code]
        browser.javascript.taint       = options[:taint]
    end

end
end
end
end
