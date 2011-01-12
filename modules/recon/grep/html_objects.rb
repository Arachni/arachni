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
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class HTMLObjects < Arachni::Module::Base

    def initialize( page )
        @page = page
    end

    def run( )
        regexp = /\<object(.*)\>(.*)\<\/object\>/im
        match_and_log( regexp )
    end

    def self.info
        {
            :name           => 'HTML objects',
            :description    => %q{Greps pages for HTML objects.},
            :author         => 'morpheuslaw <msidagni@nopsec.com>',
            :version        => '0.1',
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Found an HTML object.},
                :description => %q{},
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
