=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Credit Card Number recon check.
#
# Scans page for credit card numbers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://en.wikipedia.org/wiki/Bank_card_number
# @see http://en.wikipedia.org/wiki/Luhn_algorithm
class Arachni::Checks::CreditCard < Arachni::Check::Base

    def self.cc_regexp
        @cc_regexp ||= /\b(((4\d{3})|(5[1-5]\d{2})|(6011))[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}|3[4,7][\d\s-]{15})\b/
    end

    def self.relative_number( number )
        @relative_numder ||= {
            '0' => 0,
            '1' => 2,
            '2' => 4,
            '3' => 6,
            '4' => 8,
            '5' => 1,
            '6' => 3,
            '7' => 5,
            '8' => 7,
            '9' => 9
        }
        @relative_numder[number.to_s]
    end

    def run
        # match CC number candidates and verify matches before logging
        match_and_log( self.class.cc_regexp ){ |match| valid_credit_card?( match ) }
    end

    #
    # Checks for a valid credit card number
    #
    def valid_credit_card?( number )
        return if !valid_association?( number )

        number = number.to_s.gsub( /\D/, '' )
        number.reverse!

        sum = 0
        number.split( '' ).each_with_index do |n, i|
            sum += ( i % 2 == 0 ) ? n.to_i : self.class.relative_number( n )
        end

        sum % 10 == 0
    end

    def valid_association?( number )
        number = number.to_s.gsub( /\D/, '' )

        return :dinners  if number.length == 14 && number =~ /^3(0[0-5]|[68])/
        return :amex     if number.length == 15 && number =~ /^3[47]/
        return :visa     if [13,16].include?( number.length ) && number =~ /^4/
        return :master   if number.length == 16 && number =~ /^5[1-5]/
        return :discover if number.length == 16 && number =~ /^6011/

        nil
    end

    def self.info
        {
            name:        'Credit card number disclosure',
            description: %q{Scans pages for credit card numbers.},
            elements:    [ Element::Body ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.2.4',

            issue:       {
                name:            %q{Credit card number disclosure},
                description:     %q{
Credit card numbers are used in applications where a user is able to purchase
goods and/or services.

A credit card number is a sensitive piece of information and should be handled
as such. Cyber-criminals will use various methods to attempt to compromise credit
card information that can then be used for fraudulent purposes.

Through the use of regular expressions and CC number format validation, Arachni
was able to discover a credit card number located within the affected page.
},
                references:  {
                    'Wikipedia - Bank card number' => 'http://en.wikipedia.org/wiki/Bank_card_number',
                    'Wikipedia - Luhn algorithm'   => 'http://en.wikipedia.org/wiki/Luhn_algorithm',
                    'Luhn Ruby implementation'     => 'https://gist.github.com/1182499'
                },
                cwe:             200,
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{
Initially, the credit card number within the response should be checked to ensure
its validity, as it is possible that the regular expression has matched on a
similar number with no relation to a real credit card.

If the response does contain a valid credit card number, then all efforts should
be taken to remove or further protect this information. This can be achieved by
removing the credit card number altogether, or by masking the number so that
only the last few digits are present within the response. (eg. _**********123_).

Additionally, credit card numbers should not be stored by the application, unless
the organisation also complies with other security controls as outlined in the
Payment Card Industry Data Security Standard (PCI DSS).
},
                # Well, we can't know whether the logged number actually is an
                # CC now can we?
                trusted: false
            }
        }
    end

end
