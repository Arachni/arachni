=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Element::Capabilities
module WithScope

# Determines the {Scope scope} status of {Element::Base elements} based on
# their {Element::Base#action} and {Element::Base#type}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Scope < URI::Scope

    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < URI::Scope::Error
    end

    def initialize( element )
        @element = element
        super Arachni::URI( element.action )
    end

    # @note Will call {URI::Scope#redundant?}.
    #
    # @return   (see URI::Scope#out?)
    def out?
        begin
            return true if !Arachni::Options.audit.element?( @element.type )
        rescue Arachni::OptionGroups::Audit::Error::InvalidElementType
        end

        super || redundant?
    end

end

end
end
end
