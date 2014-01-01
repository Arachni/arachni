=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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

#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class Arachni::Modules::CAPTCHA < Arachni::Module::Base

    CAPTCHA_RX = /captcha/i

    def run
        return if !page.body =~ CAPTCHA_RX

        # since we only care about forms parse the HTML and match forms only
        page.document.css( "form" ).each do |form|
            # pretty dumb way to do this but it's a pretty dumb issue anyways...
            if (form_html = form.to_s) =~ CAPTCHA_RX
                log( regexp: CAPTCHA_RX, match: form_html, element: Element::FORM )
            end
        end
    end

    def self.info
        {
            name:        'CAPTCHA',
            description: %q{Greps pages for forms with CAPTCHAs.},
            elements:    [ Element::FORM ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.1',
            targets:     %w(Generic),
            issue:       {
                name:        %q{CAPTCHA protected form},
                description: %q{Arachni can't audit CAPTCHA protected forms, consider auditing manually.},
                severity:    Severity::INFORMATIONAL
            },
            max_issues: 25
        }
    end

end
