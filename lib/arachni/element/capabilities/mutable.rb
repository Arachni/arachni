=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
require Options.dir['lib'] + 'module/utilities'
require Options.dir['lib'] + 'module/key_filler'

module Element::Capabilities
module Mutable

    # @return   [String]    Name of the altered/mutated parameter.
    attr_accessor :altered

    # Holds constant bitfields that describe the preferred formatting
    # of injection strings.
    module Format

      # Leaves the injection string as is.
      STRAIGHT = 1 << 0

      # Appends the injection string to the default value of the input vector.<br/>
      # (If no default value exists Arachni will choose one.)
      APPEND   = 1 << 1

      # Terminates the injection string with a null character.
      NULL     = 1 << 2

      # Prefix the string with a ';', useful for command injection modules
      SEMICOLON = 1 << 3

    end

    # Default formatting and permutation options
    MUTATION_OPTIONS = {
        #
        # Formatting of the injection strings.
        #
        # A new set of audit inputs will be generated for each value in the array.
        #
        # Values can be OR'ed bitfields of all available constants of {Format}.
        #
        format:     [ Format::STRAIGHT, Format::APPEND,
                     Format::NULL, Format::APPEND | Format::NULL ],


        # Skip mutation with default/original values
        # (for {Arachni::Element::Form} elements).
        skip_orig:  false,

        # Flip injection value and input name.
        param_flip: false,

        # Array of parameter names remain untouched.
        skip:       [],

        # `nil`:   Use system settings (!Options.fuzz_methods).
        # `true`:  Don't create mutations with other methods (GET/POST).
        # `false`: Create mutations with other methods (GET/POST).
        respect_method: nil
    }

    # @return   [String]    Value of the altered input.
    def altered_value
        self[altered].to_s
    end

    # @param    [String]    value   Sets the value for the altered input.
    def altered_value=( value )
        self[altered] = value
    end

    # @return   [Bool]  `true` if the element has not been mutated, `false` otherwise.
    def original?
        self.altered.nil?
    end

    # @return   [Bool]  `true` if the element has been mutated, `false` otherwise.
    def mutated?
        !original?
    end

    # @return   [Set]   Names of input vectors to be excluded from {#mutations}.
    def immutables
        @immutables ||= Set.new
    end

    # Injects the `injection_str` in self's values according to formatting options
    # and returns an array of permutations of self.
    #
    # Vector names in {#immutables} will be excluded.
    #
    # @param    [String]  injection_str  The string to inject.
    # @param    [Hash]    opts           {MUTATION_OPTIONS}
    #
    # @yield       [mutation]  Each generated mutation.
    # @yieldparam [Mutable]
    #
    # @see #immutables
    def each_mutation( injection_str, opts = {} )
        return [] if self.auditable.empty?

        opts = MUTATION_OPTIONS.merge( opts )
        opts[:respect_method] = !Options.fuzz_methods? if opts[:respect_method].nil?

        inputs  = auditable.dup
        cinputs = Module::KeyFiller.fill( inputs )

        generated = Support::LookUp::HashSet.new

        inputs.keys.each do |k|
            # Don't audit parameter flips.
            next if inputs[k] == seed || immutables.include?( k )

            opts[:format].each do |format|

                str = format_str( injection_str, cinputs[k], format )

                elem           = self.dup
                elem.altered   = k.dup
                elem.auditable = cinputs.merge( k => str )

                yield elem if !generated.include?( elem )
                generated << elem

                next if opts[:respect_method]

                celem = elem.switch_method
                yield celem if !generated.include?( celem )
                generated << celem
            end
        end

        return if !opts[:param_flip]

        elem = self.dup

        # When under HPG mode element auditing is strictly regulated
        # and when we flip params we essentially create a new element
        # which won't be on the whitelist.
        elem.override_instance_scope

        elem.altered = 'Parameter flip'
        elem[injection_str] = seed

        yield elem if !generated.include?( elem )
        generated << elem

        return if opts[:respect_method]

        elem = elem.switch_method
        yield elem if !generated.include?( elem )
        generated << elem

        nil
    end

    def switch_method
        c = self.dup
        if c.method.to_s.downcase.to_sym == :get
            # Strip the query from the action if we're fuzzing a link
            # otherwise the GET params might get precedence.
            c.action = c.action.split( '?' ).first if c.is_a? Link
            c.method = :post
        else
            c.method = :get
        end
        c
    end

    #
    # Injects the `injection_str` in self's values according to formatting options
    # and returns an array of permutations of self.
    #
    # Vector names in {#immutables} will be excluded.
    #
    # @param    [String]  injection_str  The string to inject.
    # @param    [Hash]    opts           {MUTATION_OPTIONS}
    #
    # @return    [Array]
    #
    # @see #immutables
    #
    def mutations( injection_str, opts = {} )
        combo = []
        each_mutation( injection_str, opts ) { |m| combo << m }
        print_debug_injection_set( combo, opts )
        combo
    end

    # Alias for {#mutations}.
    def mutations_for( *args )
        mutations( *args )
    end
    # Alias for {#mutations}.
    def permutations( *args )
        mutations( *args )
    end
    # Alias for {#mutations}.
    def permutations_for( *args )
        permutations( *args )
    end

    private

    #
    # Prepares an injection string following the specified formating options
    # as contained in the format bitfield.
    #
    # @see Format
    # @param  [String]  injection_str
    # @param  [String]  default_str  default value to be appended by the
    #                                 injection string if {Format::APPEND} is set in 'format'
    # @param  [Integer]  format     bitfield describing formating preferencies
    #
    # @return  [String]
    #
    def format_str( injection_str, default_str, format  )
        semicolon = null = append = ''

        null   = "\0"        if ( format & Format::NULL )     != 0
        semicolon   = ';'    if ( format & Format::SEMICOLON )   != 0
        append = default_str if ( format & Format::APPEND )   != 0
        semicolon = append = null = ''   if ( format & Format::STRAIGHT ) != 0

        semicolon + append + injection_str.to_s + null
    end

    def print_debug_injection_set( var_combo, opts )
        return if !debug?

        print_debug
        print_debug_trainer( opts )
        print_debug_formatting( opts )
        print_debug_combos( var_combo )
    end

    def print_debug_formatting( opts )
        print_debug '------------'

        print_debug 'Injection string format combinations set to:'
        print_debug '|'
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

            prep = msg.join( ' and ' ).capitalize + ". [Combo mask: #{format}]"
            prep.gsub!( 'format::null', "Format::NULL [#{Format::NULL}]" )
            prep.gsub!( 'format::append', "Format::APPEND [#{Format::APPEND}]" )
            prep.gsub!( 'format::straight', "Format::STRAIGHT [#{Format::STRAIGHT}]" )

            print_debug "|----> #{prep}"

            msg.clear
        end
        nil
    end

    def print_debug_combos( combos )
        print_debug
        print_debug 'Prepared combinations:'
        print_debug '|'

        combos.each do |elem|
          altered = elem.altered
          combo   = elem.auditable

          print_debug '|'
          print_debug "|--> Auditing: #{altered}"
          print_debug "|--> Combo: "

          combo.each { |c_combo| print_debug "|------> #{c_combo}" }
        end

        print_debug
        print_debug '------------'
        print_debug
    end

    def print_debug_trainer( opts )
        print_debug 'Trainer set to: ' + ( opts[:train] ? 'ON' : 'OFF' )
    end

end

end
end
