=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni::Element
class Form
module Capabilities

# Extends {Arachni::Element::Capabilities::Mutable} with {Form}-specific
# functionality.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Mutable
    include Arachni::Element::Capabilities::Mutable

    # @return   [Bool]
    #   `true` if the element has not been mutated, `false` otherwise.
    def mutation_with_original_values?
        !!@mutation_with_original_values
    end

    def mutation_with_original_values
        @mutation_with_original_values = true
    end

    # @return   [Bool]
    #   `true` if the element has been populated with sample
    #   ({Arachni::OptionGroups::Input.fill}) values, `false` otherwise.
    #
    # @see Arachni::OptionGroups::Input
    def mutation_with_sample_values?
        !!@mutation_with_sample_values
    end

    def mutation_with_sample_values
        @mutation_with_sample_values = true
    end

    # Overrides {Arachni::Element::Mutable#each_mutation} adding support
    # for mutations with:
    #
    # * Sample values (filled by {Arachni::OptionGroups::Input.fill}).
    # * Original values.
    # * Password fields requiring identical values (in order to pass
    #   server-side validation)
    #
    # @param    [String]    payload
    #   Payload to inject.
    # @param    [Hash]      opts
    #   Mutation options.
    # @option   opts    [Bool]  :skip_original
    #   Whether or not to skip adding a mutation holding original values and
    #   sample values.
    #
    # @param (see Arachni::Element::Capabilities::Mutable#each_mutation)
    # @return (see Arachni::Element::Capabilities::Mutable#each_mutation)
    # @yield (see Arachni::Element::Capabilities::Mutable#each_mutation)
    # @yieldparam (see Arachni::Element::Capabilities::Mutable#each_mutation)
    #
    # @see Arachni::Element::Capabilities::Mutable#each_mutation
    # @see Arachni::OptionGroups::Input.fill
    def each_mutation( payload, opts = {} )
        opts = MUTATION_OPTIONS.merge( opts )

        generated = Arachni::Support::LookUp::HashSet.new( hasher: :mutable_id )

        # Completely remove fake inputs prior to mutation generation, they'll
        # be restored at the end of this method.
        pre_inputs = @inputs
        @inputs    = @inputs.reject{ |name, _| fake_field?( name ) }

        super( payload, opts ) do |elem|
            elem.mirror_password_fields
            yield elem if !generated.include?( elem )
            generated << elem
        end

        return if opts[:skip_original]

        elem = self.dup
        elem.mutation_with_original_values
        elem.affected_input_name = ORIGINAL_VALUES
        yield elem if !generated.include?( elem )
        generated << elem

        # Default select values, in case they reveal new resources.
        inputs.keys.each do |input|
            next if field_type_for( input ) != :select

            # We do the break inside the loop because #node is lazy parsed
            # and we don't want to parse it unless we have a select input.
            break if !node

            escape = "'#{input.split( "'" ).join( "', \"'\", '" )}', ''"
            node.xpath( "select[@name=concat(#{escape})]" ).css('option').each do |option|
                try_input do
                    elem = self.dup
                    elem.mutation_with_original_values
                    elem.affected_input_name  = input
                    elem.affected_input_value = option['value'] || option.text
                    yield elem if !generated.include?( elem )
                    generated << elem
                end
            end
        end

        try_input do
            # Sample values, in case they reveal new resources.
            elem = self.dup
            elem.inputs = Arachni::Options.input.fill( inputs.dup )
            elem.affected_input_name = SAMPLE_VALUES
            elem.mutation_with_sample_values
            yield elem if !generated.include?( elem )
            generated << elem
        end
    ensure
        @inputs = pre_inputs
    end

end
end
end
end

