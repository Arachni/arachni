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

module Arachni
module Modules

#
# Credit Card Number recon module.
#
# Scans every page for credit card numbers.
#
# @author morpheuslaw <msidagni@nopsec.com>, Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version: 0.2
#
# @see http://en.wikipedia.org/wiki/Bank_card_number
# @see http://en.wikipedia.org/wiki/Luhn_algorithm
#
class CreditCards < Arachni::Module::Base

    def run
        return if !text?

        ccNumber = /\b(((4\d{3})|(5[1-5]\d{2})|(6011))[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}|3[4,7][\d\s-]{15})\b/

        # match CC number candidates and verify matches before logging
        match_and_log( ccNumber ){
            |match|
            valid_credit_card?( match )
        }
    end

    def text?
        @page.response_headers.each {
            |k, v|
            return true if k.downcase == 'content-type' && v.include?( 'text' )
        }
        return false
    end

    #
    # Checks for a valid credit card number
    #
    def valid_credit_card?( number )
        return if !valid_association?( number )

        number = number.to_s.gsub( /\D/, '' )
        number.reverse!

        relative_number = {
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

        sum = 0

        number.split( '' ).each_with_index {
            |n, i|
            sum += ( i % 2 == 0 ) ? n.to_i : relative_number[n]
        }

        sum % 10 == 0
    end

    def valid_association?( number )
        number = number.to_s.gsub( /\D/, '' )

        return :dinners  if number.length == 14 && number =~ /^3(0[0-5]|[68])/
        return :amex     if number.length == 15 && number =~ /^3[47]/
        return :visa     if [13,16].include?(number.length) && number =~ /^4/
        return :master   if number.length == 16 && number =~ /^5[1-5]/
        return :discover if number.length == 16 && number =~ /^6011/
        return nil
    end

    def self.info
        {
            :name           => 'Credit card number disclosure',
            :description    => %q{Scans pages for credit card numbers.},
            :author         => [
                'morpheuslaw <msidagni@nopsec.com>', # original
                # updated number checks and regexp
                'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>'
            ],
            :version        => '0.2',
            :references     => {
                'Wikipedia - Bank card number' => 'http://en.wikipedia.org/wiki/Bank_card_number',
                'Wikipedia - Luhn algorithm' => 'http://en.wikipedia.org/wiki/Luhn_algorithm',
                'Luhn Ruby implementation'   => 'https://gist.github.com/1182499'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Credit card number disclosure.},
                :description => %q{A credit card number is disclosed in the body of the page.},
                :cwe         => '200',
                :severity    => Issue::Severity::MEDIUM,
                :cvssv2      => '0',
                :remedy_guidance    => %q{Remove credit card numbers from the body of the HTML pages.},
                :remedy_code => '',
            }
        }
    end

end
end
end
