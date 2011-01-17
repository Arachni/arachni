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
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class EMails < Arachni::Module::Base

    def initialize( page )
        @page = page
    end

    def run( )
        regexp = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i
        match_and_log( regexp )
    end

    def self.info
        {
            :name           => 'E-mail address',
            :description    => %q{Greps pages for disclosed e-mail addresses.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Disclosed e-mail address.},
                :description => %q{An e-mail address is being disclosed.},
                :cwe         => '200',
                :severity    => Issue::Severity::INFORMATIONAL,
                :cvssv2      => '0',
                :remedy_guidance    => %q{},
                :remedy_code => '',
            }
        }
    end

end
end
end
