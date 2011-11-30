=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Modules

#
# @author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>, haliphax
# @version: 0.1.1
#
class SSN < Arachni::Module::Base

    def initialize( page )
        @page = page
    end

    def run( )
        regexp = /\b(?!000)([0-6]\d{2}|7([0-6]\d|7[012]))([ -]?)(?!00)\d\d\3(?!0000)\d{4}\b/
        match_and_log( regexp )
    end

    def self.info
        {
            :name           => 'SSN',
            :description    => %q{Greps pages for disclosed US Social Security Numbers.},
            :author         => [
                'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>', # original
                'haliphax' # tweaked regexp
            ],
            :version        => '0.1.1',
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Disclosed US Social Security Number.},
                :description => %q{A US Social Security Number is being disclosed.},
                :cwe         => '200',
                :severity    => Issue::Severity::HIGH,
                :cvssv2      => '0',
                :remedy_guidance    => %q{Remove all SSN occurences from the page.},
                :remedy_code => '',
            }
        }
    end

end
end
end
