=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class Header
module Capabilities

# Extends {Arachni::Element::Capabilities::Mutable} with {Header}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Mutable
    include Arachni::Element::Capabilities::Mutable

    # Overrides {Capabilities::Mutable#each_mutation} to handle header-specific
    # limitations.
    #
    # @param (see Capabilities::Mutable#each_mutation)
    # @return (see Capabilities::Mutable#each_mutation)
    # @yield (see Capabilities::Mutable#each_mutation)
    # @yieldparam (see Capabilities::Mutable#each_mutation)
    #
    # @see Capabilities::Mutable#each_mutation
    def each_mutation( payload, options = {}, &block )
        parameter_names = options.delete( :parameter_names )
        super( payload, options, &block )

        return if !parameter_names

        if !valid_input_name_data?( payload )
            print_debug_level_2 'Payload not supported as input name by' <<
                                    " #{audit_id}: #{payload.inspect}"
            return
        end

        elem = self.dup
        elem.affected_input_name = FUZZ_NAME
        elem.inputs = { payload => FUZZ_NAME_VALUE }
        yield elem
    end

end

end
end
end
