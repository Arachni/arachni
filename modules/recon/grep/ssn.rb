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

#
# @author   Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>, haliphax
# @version  0.1.2
#
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
            version:     '0.1.2',
            references: {
                'ssa.gov' => 'http://www.ssa.gov/pubs/10064.html/'
            },
            targets:     %w(Generic),
            issue:       {
                name:            %q{Disclosed US Social Security Number.},
                description:     %q{A US Social Security Number is being disclosed.},
                cwe:             '200',
                severity:        Severity::HIGH,
                remedy_guidance: %q{Remove all SSN occurrences from the page.},
            }
        }
    end

end
