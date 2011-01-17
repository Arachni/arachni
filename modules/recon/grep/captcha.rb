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
class CAPTCHA < Arachni::Module::Base

    def initialize( page )
        @page = page
    end

    def run( )

        begin
            # since we only care about forms parse the HTML and match forms only
            Nokogiri::HTML( @page.body ).xpath( "//form" ).each {
                |form|
                # pretty dumb way to do this but it's a pretty dumb issue anyways...
                match_and_log( /captcha/i, form.to_s )
            }
        rescue
        end

    end

    def self.info
        {
            :name           => 'CAPTCHA',
            :description    => %q{Greps pages for forms with CAPTCHAs.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Found a CAPTCHA protected form.},
                :description => %q{Arachni can't audit CAPTCHA protected forms, consider auditing manually.},
                :cwe         => '',
                :severity    => Issue::Severity::INFORMATIONAL,
                :cvssv2      => '',
                :remedy_guidance    => %q{},
                :remedy_code => '',
            }
        }
    end

end
end
end
