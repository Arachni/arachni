=begin
    Copyright 2010-2022 Ecsypno <http://www.ecsypno.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class NestedCookie
module Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Submittable
    include Arachni::Element::Capabilities::Submittable

    def submit( options = {}, &block )
        options                   = options.dup
        options[:raw_cookies]     = [self]
        options[:follow_location] = true if !options.include?( :follow_location )

        @auditor ||= options.delete( :auditor )

        options[:performer] ||= self

        options[:raw_parameters] ||= raw_inputs

        http_request( options, &block )
    end

end

end
end
end
