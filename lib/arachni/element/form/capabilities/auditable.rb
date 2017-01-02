=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class Form
module Capabilities

# Extends {Arachni::Element::Capabilities::Auditable} with {Form}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Auditable
    include Arachni::Element::Capabilities::Auditable

    def audit_status_message
        override = nil
        if mutation_with_original_values?
            override = 'original'
        elsif mutation_with_sample_values?
            override = 'sample'
        end

        if override
            "Submitting form with #{override} values for #{inputs.keys.join(', ')}" <<
                " at '#{@action}'."
        else
            super
        end
    end

    # @param   (see Arachni::Element::Capabilities::Auditable#audit_id)
    # @return  (see Arachni::Element::Capabilities::Auditable#audit_id)
    def audit_id( payload = nil )
        force_train? ? id : super( payload )
    end

end
end
end
end
