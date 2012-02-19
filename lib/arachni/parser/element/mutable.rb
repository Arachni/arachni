=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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

require Arachni::Options.instance.dir['lib'] + 'module/utilities'
require Arachni::Options.instance.dir['lib'] + 'module/key_filler'

module Arachni
class Parser
module Element
module Mutable

    include Arachni::Module::Utilities

    attr_accessor :altered
    attr_accessor :auditor
    attr_reader   :opts

    #
    # Holds constant bitfields that describe the preferred formatting
    # of injection strings.
    #
    module Format

      #
      # Leaves the injection string as is.
      #
      STRAIGHT = 1 << 0

      #
      # Apends the injection string to the default value of the input vector.<br/>
      # (If no default value exists Arachni will choose one.)
      #
      APPEND   = 1 << 1

      #
      # Terminates the injection string with a null character.
      #
      NULL     = 1 << 2

      #
      # Prefix the string with a ';', useful for command injection modules
      #
      SEMICOLON = 1 << 3
    end

    #
    # Injects the injecton_str in self's values according to formatting options
    # and returns an array of Element permutations.
    #
    # TODO: Move type specific mutations into their respective classes.
    #
    # @param    [String]  injection_str  the string to inject
    # @param    [Hash]    opts           formatting and permutation options
    #                                       * :skip_orig => skip submission with default/original values (for {Arachni::Parser::Element::Form} elements)
    #                                       * :format => {Format}
    #                                       * :param_flip => flip injection value and input name
    #
    # @return    [Array]
    #
    def mutations( injection_str, opts = { } )

        opts = Arachni::Module::Auditor::OPTIONS.merge( opts )
        hash = auditable.dup

        var_combo = []
        return [] if !hash || hash.size == 0

        if( self.is_a?( Arachni::Parser::Element::Form ) && !opts[:skip_orig] )

            if !audited?( audit_id( Arachni::Parser::Element::Form::FORM_VALUES_ORIGINAL ) )
                # this is the original hash, in case the default values
                # are valid and present us with new attack vectors
                elem = self.dup
                elem.altered = Arachni::Parser::Element::Form::FORM_VALUES_ORIGINAL
                var_combo << elem
            end

            if !audited?( audit_id( Arachni::Parser::Element::Form::FORM_VALUES_SAMPLE ) )
                duphash = hash.dup
                elem = self.dup
                elem.auditable = Arachni::Module::KeyFiller.fill( duphash )
                elem.altered = Arachni::Parser::Element::Form::FORM_VALUES_SAMPLE
                var_combo << elem
            end
        end

        chash = hash.dup
        hash.keys.each {
            |k|

            # don't audit parameter flips
            next if hash[k] == seed

            chash = Arachni::Module::KeyFiller.fill( chash )
            opts[:format].each {
                |format|

                str  = format_str( injection_str, chash[k], format )

                elem = self.dup
                elem.altered = k.dup
                elem.auditable = chash.merge( { k => str } )
                var_combo << elem
            }

        }

        if opts[:param_flip] #&& !self.is_a?( Arachni::Parser::Element::Cookie )
            elem = self.dup

            # when under HPG mode element auditing is strictly regulated
            # and when we flip params we essentially create a new element
            # which won't be on the whitelist
            elem.override_instance_scope!

            elem.altered = 'Parameter flip'
            elem.auditable[injection_str] = seed
            var_combo << elem
        end

        # if there are two password type fields in the form there's a good
        # chance that it's a 'please retype your password' thing so make sure
        # that we have a variation which has identical password values
        if self.is_a?( Arachni::Parser::Element::Form )
            chash = hash.dup
            chash = Arachni::Module::KeyFiller.fill( chash )
            delem = self.dup

            add = false
            @raw['auditable'].each {
                |input|

                if input['type'] == 'password'
                    delem.altered = input['name']

                    opts[:format].each {
                        |format|
                        chash[input['name']] =
                            format_str( injection_str, chash[input['name']], format )
                    }

                    add = true
                end
            } if @raw['auditable']

            if add
                delem.auditable = chash
                var_combo << delem
            end
        end


        print_debug_injection_set( var_combo, opts )

        return var_combo
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

        return semicolon + append + injection_str.to_s + null
    end

end

end
end
end
