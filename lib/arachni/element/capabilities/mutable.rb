=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
module Element::Capabilities

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    module Format

      # Leaves the injection string as is.
      STRAIGHT = 1 << 0

      # Appends the injection string to the default value of the input vector.<br/>
      # (If no default value exists Arachni will choose one.)
      APPEND   = 1 << 1

      # Terminates the injection string with a null character.
      NULL     = 1 << 2

      # Prefix the string with a ';', useful for command injection checks
      SEMICOLON = 1 << 3

    end

    # Default formatting and mutation options.
    MUTATION_OPTIONS = {
        #
        # Formatting of the injection strings.
        #
        # A new set of audit inputs will be generated for each value in the array.
        #
        # Values can be OR'ed bitfields of all available constants of {Format}.
        #
        format:         [ Format::STRAIGHT, Format::APPEND,
                            Format::NULL, Format::APPEND | Format::NULL ],

        # Flip injection value and input name.
        param_flip:     false,

        # Array of parameter names remain untouched.
        skip:           [],

        # `nil`:   Use system settings (!Options.audit.with_both_http_methods).
        # `true`:  Don't create mutations with other methods (GET/POST).
        # `false`: Create mutations with other methods (GET/POST).
        respect_method: nil
    }

    # Resets the inputs to their original format/values.
    def reset
        super
        @affected_input_name = nil
        @seed                = nil
        self
    end

    # @return   [ni, String]
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

    # @param    [String]    value
    #   Sets the name of the fuzzed input.
    def affected_input_name=( value )
        @affected_input_name = value.to_s
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

    # @note Vector names in {#immutables} will be excluded.
    #
    # Injects the `payload` in self's values according to formatting options
    # and returns an array of mutations of self.
    #
    # @param    [String]  payload
    #   String to inject.
    # @param    [Hash]    opts
    #   {MUTATION_OPTIONS}
    #
    # @yield       [mutation]
    #   Each generated mutation.
    # @yieldparam [Mutable]
    #
    # @see #immutables
    def each_mutation( payload, opts = {} )
        return if self.inputs.empty?

        if !valid_input_data?( payload )
            print_debug_level_2 "Payload not supported by #{self}: #{payload.inspect}"
            return
        end

        print_debug_trainer( opts )
        print_debug_formatting( opts )

        opts = MUTATION_OPTIONS.merge( opts )
        opts[:respect_method] = !Options.audit.with_both_http_methods? if opts[:respect_method].nil?

        dinputs = inputs.dup
        cinputs = Options.input.fill( inputs )

        generated = Support::LookUp::HashSet.new( hasher: :inputtable_id )

        dinputs.keys.each do |k|
            # Don't audit parameter flips.
            next if dinputs[k] == seed || immutables.include?( k )

            opts[:format].each do |format|
                str = format_str( payload, cinputs[k], format )

                if !valid_input_value_data?( str )
                    print_debug_level_2 'Payload not supported as input value by' <<
                                            " #{audit_id}: #{str.inspect}"
                    next
                end

                elem                     = self.dup
                elem.seed                = payload
                elem.affected_input_name = k.dup
                elem.inputs              = cinputs.merge( k => str )
                elem.format              = format

                if !generated.include?( elem )
                    print_debug_mutation elem
                    yield elem
                end

                generated << elem

                next if opts[:respect_method]

                celem = elem.switch_method
                if !generated.include?( celem )
                    print_debug_mutation elem
                    yield celem
                end
                generated << celem
            end
        end

        if opts[:param_flip]
            if valid_input_name_data?( payload )
                elem                     = self.dup
                elem.affected_input_name = 'Parameter flip'
                elem[payload]            = seed
                elem.seed                = payload

                if !generated.include?( elem )
                    print_debug_mutation elem
                    yield elem
                end
                generated << elem
            else
                print_debug_level_2 'Payload not supported as input name by' <<
                                        " #{audit_id}: #{payload.inspect}"
                return
            end
        end

        if !opts[:respect_method]
            elem = switch_method
            if !generated.include?( elem )
                print_debug_mutation elem
                yield elem
            end
            generated << elem
        end

        nil
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

    def dup
        copy_mutable( super )
    end

    private

    def copy_mutable( other )
        if self.affected_input_name
            other.affected_input_name = self.affected_input_name.dup
        end

        other.seed   = self.seed.dup if self.seed
        other.format = self.format
        other
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
    def format_str( payload, default_str, format  )
        semicolon = null = append = nil

        null      = "\0"               if (format & Format::NULL)      != 0
        semicolon = ';'                if (format & Format::SEMICOLON) != 0
        append    = default_str        if (format & Format::APPEND)    != 0
        semicolon = append = null = '' if (format & Format::STRAIGHT)  != 0

        "#{semicolon}#{append}#{payload}#{null}"
    end

    def print_debug_injection_set( mutations, opts )
        return if !debug_level_2?

        print_debug_level_2
        print_debug_trainer( opts )
        print_debug_formatting( opts )
        print_debug_combos( mutations )
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

            prep = msg.join( ' and ' ).capitalize + ". [Format mask: #{format}]"
            prep.gsub!( 'format::null', "Format::NULL [#{Format::NULL}]" )
            prep.gsub!( 'format::append', "Format::APPEND [#{Format::APPEND}]" )
            prep.gsub!( 'format::straight', "Format::STRAIGHT [#{Format::STRAIGHT}]" )

            print_debug_level_2 "|----> #{prep}"

            msg.clear
        end
        nil
    end

    def print_debug_combos( mutations )
        return if !debug_level_2?

        print_debug_level_2
        print_debug_level_2 'Prepared mutations:'
        print_debug_level_2 '|'

        mutations.each do |mutation|
            print_debug_mutation mutation
        end

        print_debug_level_2
        print_debug_level_2 '------------'
        print_debug_level_2
    end

    def print_debug_mutation( mutation )
        return if !debug_level_2?

        print_debug_level_2 '|'
        print_debug_level_2 "|--> Auditing: #{mutation.affected_input_name}"

        print_debug_level_2 '|--> Inputs: '
        mutation.inputs.each do |k, v|
            print_debug_level_2 "|----> #{k.inspect} => #{v.inspect}"
        end
    end

    def print_debug_trainer( opts )
        print_debug_level_2 "Trainer set to: #{opts[:train] ? 'ON' : 'OFF'}"
    end

end

end
end
