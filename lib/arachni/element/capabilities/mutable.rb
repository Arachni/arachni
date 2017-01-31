=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Mutable

    # @return     [String]
    #   Name of the mutated parameter.
    attr_accessor :affected_input_name

    # @return     [String]
    #   Original seed used for the {#mutations}.
    attr_accessor :seed

    attr_accessor :format

    # Bitfields that describe the common payload formatting options.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    module Format

      # Leaves the injection string as is.
      STRAIGHT  = 1 << 0

      # Appends the injection string to the default value of the input vector.<br/>
      # (If no default value exists Arachni will choose one.)
      APPEND    = 1 << 1

      # Terminates the injection string with a null character.
      NULL      = 1 << 2

      # Prefix the string with a ';', useful for command injection checks
      SEMICOLON = 1 << 3

    end

    # Default formatting and mutation options.
    MUTATION_OPTIONS = {

        # Formatting of the injection strings.
        #
        # A new set of audit inputs will be generated for each value in the array.
        #
        # Values can be OR'ed bitfields of all available constants of {Format}.
        format:                 [
            Format::STRAIGHT, Format::APPEND,
            Format::NULL, Format::APPEND | Format::NULL
        ],

        # Inject the payload into parameter values.
        #
        # * `nil`: Use system settings (`!Options.audit.parameter_values`).
        # * `true`
        # * `false`
        parameter_values:       nil,

        # Place the payload as an input name.
        #
        # * `nil`: Use system settings (`!Options.audit.parameter_names`).
        # * `true`
        # * `false`
        parameter_names:        nil,

        # Add mutations with non-encoded payloads.
        #
        # * `nil`: Use system settings (`!Options.audit.with_raw_parameters`).
        # * `true`
        # * `false`
        with_raw_payloads:       nil,

        # Add the payload to an extra parameter.
        #
        # * `nil`: Use system settings (`!Options.audit.with_extra_parameter`).
        # * `true`
        # * `false`
        with_extra_parameter:   nil,

        # `nil`:   Use system settings (`!Options.audit.with_both_http_methods`).
        # `true`:  Don't create mutations with other methods (GET/POST).
        # `false`: Create mutations with other methods (GET/POST).
        with_both_http_methods: nil,

        # Array of parameter names remain untouched.
        skip:                   []
    }

    EXTRA_NAME      = 'extra_arachni_input'
    FUZZ_NAME       = 'Parameter name fuzzing'
    FUZZ_NAME_VALUE = 'arachni_name_fuzz'

    # Resets the inputs to their original format/values.
    def reset
        super
        @affected_input_name = nil
        @seed                = nil
        self
    end

    # @return   [nil, String]
    #   `nil` if no input has been fuzzed, the `String` value of the fuzzed
    #   input.
    def affected_input_value
        return if !affected_input_name
        self[affected_input_name].to_s
    end

    # @param    [String]    value
    #   Sets the value for the fuzzed input.
    def affected_input_value=( value )
        self[affected_input_name] = value
    end

    # @param    [String]    name
    #   Sets the name of the fuzzed input.
    def affected_input_name=( name )
        @affected_input_name = name.to_s
    end

    # @param    [String]    value
    #   Sets the value for the fuzzed input.
    def seed=( value )
        @seed = value.to_s
    end

    # @return   [Bool]
    #   `true` if the element has been mutated, `false` otherwise.
    def mutation?
        !!self.affected_input_name
    end

    # @return   [Set]
    #   Names of input vectors to be excluded from {#mutations}.
    def immutables
        @immutables ||= Set.new
    end

    # @return   [Boolean]
    #   `true` if the mutation's {#affected_input_value} has been set to skip
    #   encoding, `false` otherwise.
    def with_raw_payload?
        raw_inputs.include? affected_input_name
    end

    # @note Vector names in {#immutables} will be excluded.
    #
    # Injects the `payload` in self's values according to formatting options
    # and returns an array of mutations of self.
    #
    # @param    [String]  payload
    #   String to inject.
    # @param    [Hash]    options
    #   {MUTATION_OPTIONS}
    #
    # @yield       [mutation]
    #   Each generated mutation.
    # @yieldparam [Mutable]
    #
    # @see #immutables
    def each_mutation( payload, options = {}, &block )
        return if self.inputs.empty?

        if !valid_input_data?( payload )
            print_debug_level_2 "Payload not supported by #{self}: #{payload.inspect}"
            return
        end

        print_debug_trainer( options )
        print_debug_formatting( options )

        options          = prepare_mutation_options( options )
        generated        = Support::LookUp::HashSet.new
        filled_in_inputs = Options.input.fill( @inputs )

        if options[:parameter_values]
            @inputs.keys.each do |name|
                # Don't let parameter name pollution from an old audit of an
                # input name trick us into doing the same for elements without
                # that option.
                next if name == EXTRA_NAME
                next if immutables.include?( name )

                each_formatted_payload(
                    payload, options[:format], filled_in_inputs[name]
                ) do |format, formatted_payload|

                    elem = create_and_yield_if_unique(
                        generated, filled_in_inputs, payload, name,
                        formatted_payload, format, &block
                    )

                    next if !elem

                    if options[:with_raw_payloads]
                        yield_if_unique( elem.with_raw_payload, generated, &block )
                    end

                    if options[:with_both_http_methods]
                        yield_if_unique( elem.switch_method, generated, &block )
                    end
                end
            end
        end

        if options[:with_extra_parameter]
            if valid_input_name?( EXTRA_NAME )
                each_formatted_payload( payload, options[:format] ) do |format, formatted_payload|

                    elem = create_and_yield_if_unique(
                        generated, filled_in_inputs.merge( EXTRA_NAME => '' ),
                        payload, EXTRA_NAME, formatted_payload, format, &block
                    )

                    next if !elem || !options[:with_both_http_methods]
                    yield_if_unique( elem.switch_method, generated, &block )
                end
            else
                print_debug_level_2 'Extra name not supported as input name by' <<
                                        " #{audit_id}: #{payload.inspect}"
            end
        end

        if options[:parameter_names]
            if valid_input_name_data?( payload )
                elem                     = self.dup.update( filled_in_inputs )
                elem.affected_input_name = FUZZ_NAME
                elem[payload]            = FUZZ_NAME_VALUE
                elem.seed                = payload

                yield_if_unique( elem, generated, &block )
            else
                print_debug_level_2 'Payload not supported as input name by' <<
                                        " #{audit_id}: #{payload.inspect}"
            end
        end

        nil
    end

    def parameter_name_audit?
        affected_input_name == FUZZ_NAME
    end

    def with_raw_payload
        self.dup.tap do |c|
            c.raw_inputs << c.affected_input_name
        end
    end

    def switch_method
        self.dup.tap { |c| c.method = (c.method == :get ? :post : :get) }
    end

    # Injects the `payload` in self's values according to formatting
    # options and returns an array of mutations of self.
    #
    # Vector names in {#immutables} will be excluded.
    #
    # @param    [String]  payload
    #   The string to inject.
    # @param    [Hash]    opts
    #   {MUTATION_OPTIONS}
    #
    # @return    [Array]
    #
    # @see #immutables
    def mutations( payload, opts = {} )
        combo = []
        each_mutation( payload, opts ) { |m| combo << m }
        combo
    end

    def to_h
        h = super

        if mutation?
            h[:affected_input_name]  = self.affected_input_name
            h[:affected_input_value] = self.affected_input_value
            h[:seed]                 = self.seed
        end

        h
    end

    def inspect
        s = "#<#{self.class} (#{http_method}) "

        if !orphan?
            s << "auditor=#{auditor.class} "
        end

        s << "url=#{url.inspect} "
        s << "action=#{action.inspect} "

        s << "default-inputs=#{default_inputs.inspect} "
        s << "inputs=#{inputs.inspect} "
        s << "raw_inputs=#{raw_inputs.inspect} "

        if mutation?
            s << "seed=#{seed.inspect} "
            s << "affected-input-name=#{affected_input_name.inspect} "
            s << "affected-input-value=#{affected_input_value.inspect}"
        end

        s << '>'
    end

    def to_rpc_data
        d = super
        d.delete 'immutables'
        d
    end

    def dup
        copy_mutable( super )
    end

    protected

    def mutable_id
        Arachni::Element::Capabilities::Mutable.mutable_id(
            method,
            inputs,
            raw_inputs
        )
    end

    def self.mutable_id( method, inputs, raw_inputs )
        "#{method}:#{Arachni::Element::Capabilities::Inputtable.inputtable_id( inputs, raw_inputs )}"
    end

    private

    def prepare_mutation_options( options )
        options = MUTATION_OPTIONS.merge( options )

        if options[:with_raw_payloads].nil?
            options[:with_raw_payloads] = Options.audit.with_raw_payloads?
        end

        if options[:parameter_values].nil?
            options[:parameter_values] = Options.audit.parameter_values?
        end

        if options[:parameter_names].nil?
            options[:parameter_names] = Options.audit.parameter_names?
        end

        if options[:with_extra_parameter].nil?
            options[:with_extra_parameter] = Options.audit.with_extra_parameter?
        end

        if options[:with_both_http_methods].nil?
            options[:with_both_http_methods] = Options.audit.with_both_http_methods?
        end

        options
    end

    def copy_mutable( other )
        if self.affected_input_name
            other.affected_input_name = self.affected_input_name.dup
        end

        other.seed       = self.seed.dup if self.seed
        other.format     = self.format

        # Carry over the immutables.
        other.immutables.merge self.immutables
        other
    end

    def create_mutation( inputs, seed, input_name, input_value, format )
        if !valid_input_value_data?( input_value )
            print_debug_level_2 "Value not supported by #{audit_id}: #{input_value.inspect}"
            return
        end

        if !valid_input_name_data?( input_name )
            print_debug_level_2 "Name not supported by #{audit_id}: #{input_name.inspect}"
            return
        end

        elem                      = self.dup.update( inputs )
        elem.seed                 = seed
        elem.affected_input_name  = input_name
        elem.affected_input_value = input_value
        elem.format               = format

        elem
    end

    def create_and_yield_if_unique(
        list, inputs, seed, input_name, input_value,format, &block
    )
        # We can check if it's unique prior to actually creating, so do it.
        return if list.include?(
            Arachni::Element::Capabilities::Mutable.mutable_id(
                self.method,
                inputs,
                []
            )
        )

        element = create_mutation( inputs, seed, input_name, input_value, format )
        return if !element

        yield_if_unique( element, list, &block )
        element
    end

    def yield_if_unique( element, list )
        return if list.include?( element.mutable_id )

        print_debug_mutation element
        list << element

        yield element
    end

    def each_formatted_payload( payload, formats, default_value = '' )
        formats.each do |format|
            yield format, format_str( payload, format, default_value )
        end
    end

    # Prepares an injection string following the specified formatting options
    # as contained in the format bitfield.
    #
    # @param  [String]  payload
    # @param  [String]  default_str
    #   Default value to be appended by the injection string if {Format::APPEND}
    #   is set in 'format'.
    # @param  [Integer]  format
    #   Bitfield describing formatting preferences.
    #
    # @return  [String]
    #
    # @see Format
    def format_str( payload, format, default_str = '' )
        semicolon = null = append = nil

        null      = "\0"               if (format & Format::NULL)      != 0
        semicolon = ';'                if (format & Format::SEMICOLON) != 0
        append    = default_str        if (format & Format::APPEND)    != 0
        semicolon = append = null = '' if (format & Format::STRAIGHT)  != 0

        "#{semicolon}#{append}#{payload}#{null}"
    end

    def print_debug_formatting( opts )
        return if !opts[:format] || !debug_level_2?

        print_debug_level_2

        print_debug_level_2 'Formatting set to:'
        print_debug_level_2 '|'
        msg = []
        opts[:format].each do |format|
            if( format & Format::NULL ) != 0
                msg << 'null character termination (Format::NULL)'
            end

            if( format & Format::APPEND ) != 0
                msg << 'append to default value (Format::APPEND)'
            end

            if( format & Format::STRAIGHT ) != 0
                msg << 'straight, leave as is (Format::STRAIGHT)'
            end

            prep = "#{msg.join( ' and ' ).capitalize}. [Format mask: #{format}]"
            prep.gsub!( 'format::null', "Format::NULL [#{Format::NULL}]" )
            prep.gsub!( 'format::append', "Format::APPEND [#{Format::APPEND}]" )
            prep.gsub!( 'format::straight', "Format::STRAIGHT [#{Format::STRAIGHT}]" )

            print_debug_level_2 "|----> #{prep}"

            msg.clear
        end
        nil
    end

    def print_debug_mutation( mutation )
        return if !debug_level_2?

        print_debug_level_2 '|'
        print_debug_level_2 "|--> Auditing: #{mutation.affected_input_name}"

        print_debug_level_2 '|--> Inputs: '
        mutation.inputs.each do |k, v|
            print_debug_level_2 "|----> #{k.inspect} => #{v.inspect}"
        end

        if mutation.raw_inputs.any?
            print_debug_level_2 '|--> Raw inputs: '
            mutation.raw_inputs.each do |k|
                print_debug_level_2 "|----> #{k.inspect}"
            end
        end
    end

    def print_debug_trainer( opts )
        print_debug_level_2 "Trainer set to: #{opts[:train] ? 'ON' : 'OFF'}"
    end

end

end
end
