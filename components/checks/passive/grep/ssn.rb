=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author   Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>, haliphax
class Arachni::Checks::Ssn < Arachni::Check::Base

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
                'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>', # original
                'haliphax' # tweaked regexp
            ],
            version:     '0.1.4',

            issue:       {
                name:            %q{Disclosed US Social Security Number (SSN)},
                description:     %q{
The US Social Security Number (SSN) is a personally identifiable number that is
issued to its citizens.

A stolen or leaked SSN can lead to a compromise, and/or the theft of the affected
individual's identity.

Through the use of regular expressions, Arachni has discovered an SSN located
within the response of the affected page.
},
                references: {
                    'ssa.gov' => 'http://www.ssa.gov/pubs/10064.html'
                },
                cwe:             200,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
Initially, the SSN within the response should be checked to ensure its validity,
as it is possible that the regular expression has matched a similar number with
no relation to a real SSN.

If the response does contain a valid SSN, then all efforts should be taken to
remove or further protect this information. This can be achieved by removing the
SSN altogether or by masking the number so that only the last few digits are
present within the response (eg. _**********123_).
},
                # Well, we can't know whether the logged number actually is an
                # SSN now can we?
                trusted: false
            }
        }
    end

end
