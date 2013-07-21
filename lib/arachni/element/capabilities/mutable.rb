=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni
require Options.dir['lib'] + 'module/utilities'
require Options.dir['lib'] + 'module/key_filler'

module Element::Capabilities
module Mutable

    # @return   [String]    Name of the altered/mutated parameter.
    attr_accessor :altered

    attr_accessor :format

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
        skip_original:  false,

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
        opts = MUTATION_OPTIONS.merge( opts )
        hash = inputs.dup

        var_combo = []
        return [] if !hash || hash.empty?

        chash = hash.dup
        hash.keys.each do |k|
            # don't audit parameter flips
            next if hash[k] == seed || immutables.include?( k )

            chash = Module::KeyFiller.fill( chash )
            opts[:format].each do |format|
                str = format_str( injection_str, chash[k], format )

                elem = self.dup
                elem.altered = k.dup
                elem.format  = format
                elem.inputs = chash.merge( { k => str } )
                var_combo << elem
            end

        end

        if opts[:param_flip]
            elem = self.dup

            # when under HPG mode element auditing is strictly regulated
            # and when we flip params we essentially create a new element
            # which won't be on the whitelist
            elem.override_instance_scope

            elem.altered = 'Parameter flip'
            elem[injection_str] = seed
            var_combo << elem
        end

        opts[:respect_method] = !Options.fuzz_methods? if opts[:respect_method].nil?

        # add the same stuff with different methods
        if !opts[:respect_method]
            var_combo |= var_combo.map do |f|
                c = f.dup
                c.method = (f.method.to_s.downcase == 'get' ? 'post' : 'get')
                c
            end
        end

        print_debug_injection_set( var_combo, opts )
        var_combo.uniq
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
          combo   = elem.inputs

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
