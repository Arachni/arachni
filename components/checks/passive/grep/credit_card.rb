=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

#
# Credit Card Number recon check.
#
# Scans page for credit card numbers.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.2.2
#
# @see http://en.wikipedia.org/wiki/Bank_card_number
# @see http://en.wikipedia.org/wiki/Luhn_algorithm
#
class Arachni::Checks::CreditCards < Arachni::Check::Base

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

    # TODO: Someone needs to re-check these associations, some don't
    #   work and I've no idea how to resolve this.
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
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2.2',

            issue:       {
                name:            %q{Credit card number disclosure},
                description:     %q{A credit card number is disclosed in the body of the page.},
                references:  {
                    'Wikipedia - Bank card number' => 'http://en.wikipedia.org/wiki/Bank_card_number',
                    'Wikipedia - Luhn algorithm'   => 'http://en.wikipedia.org/wiki/Luhn_algorithm',
                    'Luhn Ruby implementation'     => 'https://gist.github.com/1182499'
                },
                cwe:             200,
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{Remove credit card numbers from the body of the HTML pages.},
            }
        }
    end

end
