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
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class CAPTCHA < Arachni::Module::Base

    def run

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
