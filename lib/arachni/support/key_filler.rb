=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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

module Arachni::Support

# Tries to fill in input parameters with values of proper type based on their name.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class KeyFiller
class <<self

    # @return [Hash<Regexp, String>]
    #   Patterns for parameter names and the values to to fill in.
    def regexps
        @regexps ||= {
            /name/i    => 'arachni_name',
            /user/i    => 'arachni_user',
            /usr/i     => 'arachni_user',
            /pass/i    => '5543!%arachni_secret',
            /txt/i     => 'arachni_text',
            /num/i     => '132',
            /amount/i  => '100',
            /mail/i    => 'arachni@email.gr',
            /account/i => '12',
            /id/i      => '1'
        }
    end

    # Tries to fill a hash with values of appropriate type based on the key of
    # the parameter.
    #
    # @param  [Hash]  parameters   Parameters hash.
    # @param  [String]  default   Default value to use if no match was found.
    #
    # @return   [Hash]
    def fill( parameters, default = '1' )
        parameters = parameters.dup
        parameters.each do |k, v|
            next if !v.to_s.empty?
            # moronic default value...
            # will figure  out something better in the future...
            parameters[k] = name_to_value( k, default )
        end
        parameters
    end

    def name_to_value( name, default = nil )
        regexps.each { |k, v| return v if name =~ k }
        default.to_s
    end

end
end

end
