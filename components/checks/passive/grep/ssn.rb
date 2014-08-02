=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# @author   Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>, haliphax
# @version  0.1.2
class Arachni::Checks::SSN < Arachni::Check::Base

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
            elements:    [ Element::Body ],
            author:      [
                'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>', # original
                'haliphax' # tweaked regexp
            ],
            version:     '0.1.2',

            issue:       {
                name:            %q{Disclosed US Social Security Number (SSN)},
                description:     %q{A US Social Security Number is being disclosed.},
                references: {
                    'ssa.gov' => 'http://www.ssa.gov/pubs/10064.html'
                },
                cwe:             200,
                severity:        Severity::HIGH,
                remedy_guidance: %q{Remove all SSN occurrences from the page.},
            }
        }
    end

end
