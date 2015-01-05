=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

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

    # Overrides {Arachni::Element::Capabilities::Mutable#each_mutation} to handle
    # XML-specific limitations.
    #
    # @param (see Arachni::Element::Capabilities::Mutable#each_mutation)
    # @return (see Arachni::Element::Capabilities::Mutable#each_mutation)
    # @yield (see Arachni::Element::Capabilities::Mutable#each_mutation)
    # @yieldparam (see Arachni::Element::Capabilities::Mutable#each_mutation)
    #
    # @see Arachni::Element::Capabilities::Mutable#each_mutation
    def each_mutation( payload, options = {}, &block )
        options.delete( :parameter_names )
        options.delete( :with_extra_parameter )
        super( payload, options, &block )
    end

end

end
end
end
