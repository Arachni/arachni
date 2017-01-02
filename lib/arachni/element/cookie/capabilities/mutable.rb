=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class Cookie
module Capabilities

# Extends {Arachni::Element::Capabilities::Mutable} with {Cookie}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Mutable
    include Arachni::Element::Capabilities::Mutable

    # Overrides {Arachni::Element::Capabilities::Mutable#each_mutation} to handle cookie-specific
    # limitations and the {Arachni::OptionGroups::Audit#cookies_extensively} option.
    #
    # @param (see Arachni::Element::Capabilities::Mutable#each_mutation)
    # @return (see Arachni::Element::Capabilities::Mutable#each_mutation)
    # @yield (see Arachni::Element::Capabilities::Mutable#each_mutation)
    # @yieldparam (see Arachni::Element::Capabilities::Mutable#each_mutation)
    #
    # @see Arachni::Element::Capabilities::Mutable#each_mutation
    def each_mutation( payload, options = {}, &block )
        options              = prepare_mutation_options( options )
        parameter_names      = options.delete( :parameter_names )
        with_extra_parameter = options.delete( :with_extra_parameter )
        extensively          = options[:extensively]
        extensively          = Arachni::Options.audit.cookies_extensively? if extensively.nil?

        super( payload, options ) do |element|
            yield element

            next if !extensively
            element.each_extensive_mutation( element, &block )
        end

        if with_extra_parameter
            if valid_input_name?( EXTRA_NAME )
                each_formatted_payload( payload, options[:format] ) do |format, formatted_payload|

                    element                     = self.dup
                    element.affected_input_name = EXTRA_NAME
                    element.inputs              = { EXTRA_NAME => formatted_payload }
                    element.format              = format
                    yield element if block_given?
                end
            else
                print_debug_level_2 'Extra name not supported as input name by' <<
                                        " #{audit_id}: #{payload.inspect}"
            end
        end

        if parameter_names
            if valid_input_name_data?( payload )
                element                     = self.dup
                element.affected_input_name = FUZZ_NAME
                element.inputs              = { payload => FUZZ_NAME_VALUE }
                element.seed                = payload
                yield element if block_given?
            else
                print_debug_level_2 'Payload not supported as input name by' <<
                                        " #{audit_id}: #{payload.inspect}"
            end
        end

        nil
    end

    def each_extensive_mutation( mutation )
        return if orphan?

        (auditor.page.links | auditor.page.forms).each do |e|
            next if e.inputs.empty?

            c = e.dup
            c.affected_input_name = "Mutation for the '#{name}' cookie"
            c.auditor = auditor
            c.audit_options[:submit] ||= {}
            c.audit_options[:submit][:cookies] = mutation.inputs.dup
            c.inputs = Arachni::Options.input.fill( c.inputs.dup )

            yield c
        end
    end

    private

    def prepare_mutation_options( options )
        options = super( options )
        options.delete( :with_raw_payloads )
        options
    end

end

end
end
end
