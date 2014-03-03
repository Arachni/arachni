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

# @author   Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>, haliphax
# @version  0.1.3
class Arachni::Modules::SSN < Arachni::Module::Base

    def self.regexp
        @regexp ||= /\b(((?!000)(?!666)(?:[0-6]\d{2}|7[0-2][0-9]|73[0-3]|7[5-6][0-9]|77[0-2]))-((?!00)\d{2})-((?!0000)\d{4}))\b/
    end

    def run
        match_and_log( self.class.regexp ){ |m| m.gsub( /\D/, '' ).size == 9 }
    end

    def self.info
        {
            name:        'SSN',
            description: %q{Greps pages for disclosed US Social Security Numbers.},
            elements:    [ Element::BODY ],
            author:      [
                'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>', # original
                'haliphax' # tweaked regexp
            ],
            version:     '0.1.3',
            targets:     %w(Generic),
            references: {
                'ssa.gov' => 'http://www.ssa.gov/pubs/10064.html'
            },
            issue:       {
                name:            %q{Disclosed US Social Security Number (SSN)},
                description:     %q{The US Social Security Number (SSN) is a 
                    personally identifiable number that is issued to its 
                    citizens. A stolen or leaked SSN can lead to a compromise, 
                    and/or the theft of the affected individual's identity. 
                    Through the use of regular expressions, Arachni has discovered
                    a SSN located within the response of the affected page.},
                cwe:             '200',
                severity:        Severity::HIGH,
                remedy_guidance: %q{Initially, the SSN within the response 
                    should be checked to ensure its validity, as it is possible 
                    that the regular expression has matched a similar number
                    with no relation to a real SSN. If the response does contain 
                    a valid SSN, then all efforts should be taken to remove or
                    further protect this information. This can be achieved by 
                    removing the SSN all together or by masking the number so
                    that only the last few digits are present within the 
                    response. eg. **********123.},
            }
        }
    end

end
