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

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.2
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
            version:     '0.1.2',
            references:  {
                'WASC' => 'http://projects.webappsec.org/w/page/13246938/Insufficient%20Anti-automation',
            },
            targets:     %w(Generic),
            issue:       {
                name:        %q{CAPTCHA protected form},
                description: %q{To prevent the automated abuse of a page, 
                    applications can implement what is known as a CAPTCHA. These 
                    are used to ensure human interaction with the application, 
                    and are often used on forms where the application conducts 
                    sensitive actions. These typically include user registration,
                    or submitting emails via the contact us page etc. Arachni
                    has flagged this not as a vulnerability, but as a prompt for 
                    the penetration tester to conduct further manual testing on 
                    the CAPTCHA function, as Arachni cannon audit CAPTCHA
                    protected forms. Testing for insecurely implemented CAPTCHA 
                    is a manual process, and an insecurely implemented CAPTCHA 
                    could allow a cyber-criminal a means to abuse these sensitive actions. },
                severity:    Severity::INFORMATIONAL,
                remedy_guidance: %q{Although no remediation may be required 
                    based off of this finding alone, manual testing should 
                    ensure that: 1. The server keeps track of CAPTCHA tokens in 
                    use, and has the token terminated by the server after first 
                    use or after a period of time. Therefore preventing replay
                    attacks 2. The CAPTCHA answer is not hidden in plain text 
                    within the response that is sent to the client. 3. The 
                    CAPTCHA image should not be weak and easily solved.},
            },
            max_issues: 25
        }
    end

end
