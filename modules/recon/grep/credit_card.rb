=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Modules

#
# Credit Card Number recon module.
#
# Scans every page for credit card numbers.
#
# @author: morpheuslaw <msidagni@nopsec.com>
# @version: 0.1
#
class CreditCards < Arachni::Module::Base

    def initialize( page )
        @page = page
    end

    def run( )
        ccNumber = /^(((4\d{3})|(5[1-5]\d{2})|(6011))-?\d{4}-?\d{4}-?\d{4}|3[4,7][\d\s-]{15})$/

        # match CC number candidates and verify matches before logging
        match_and_log( ccNumber ){
            |match|
            __luhn_check( match )
        }
    end

    #
    # Checks for a valid credit card number
    #
    def __luhn_check( cc_number )
      cc_number   = cc_number.gsub( /D/, '' )
      cc_length   = cc_number.length
      parity      = cc_length % 2

      sum = 0
      for i in 0..cc_length
         digit = cc_number[i].to_i - 48

         if i % 2 == parity
           digit = digit * 2
         end

         if digit > 9
           digit = digit - 9
         end

         sum = sum + digit
      end

      return (sum % 10) == 0
    end

    def self.info
        {
            :name           => 'Credit card number disclosure',
            :description    => %q{Scans pages for credit card numbers.},
            :author         => 'morpheuslaw <msidagni@nopsec.com>',
            :version        => '0.1',
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{Credit card number disclosure.},
                :description => %q{A credit card number is disclosed in the body of the page.},
                :cwe         => '200',
                :severity    => Vulnerability::Severity::MEDIUM,
                :cvssv2      => '0',
                :remedy_guidance    => %q{Remove credit card numbers from the body of the HTML pages.},
                :remedy_code => '',
            }
        }
    end

end
end
end
