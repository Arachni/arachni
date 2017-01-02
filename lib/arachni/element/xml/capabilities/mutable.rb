=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class XML
module Capabilities

# Extends {Arachni::Element::Capabilities::Mutable} with {XML}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Mutable
    include Arachni::Element::Capabilities::Mutable

    private

    def prepare_mutation_options( options )
        options = super( options )
        options.delete( :with_raw_payloads )
        options.delete( :parameter_names )
        options.delete( :with_extra_parameter )
        options
    end
end

end
end
end
