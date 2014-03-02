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
# Greps pages for forms which have password fields without explicitly
# disabling auto-complete.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2
#
class Arachni::Modules::PasswordAutocomplete < Arachni::Module::Base

    def run
        page.forms.each do |form|
            next if !form.requires_password?
            next if form.raw['attrs'] && form.raw['attrs']['autocomplete'] == 'off'
            next if form.raw['input'].map { |i| i['autocomplete'] == 'off' }.
                                    include?( true )

            log( var: form.name_or_id, match: form.to_html, element: Element::FORM )
        end
    end

    def self.info
        {
            name:        'Password field with auto-complete',
            description: %q{Greps pages for forms which have password fields
                without explicitly disabling auto-complete.},
            elements:    [ Element::FORM ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2',
            targets:     %w(Generic),
            issue:       {
                name:        %q{Password field with auto-complete},
                description: %q{In typical form based web applications, it is 
                    common practice for developers to allow autocomplete within 
                    the HTML form to improve the usability of the page. With 
                    autocomplete enabled (default) it allows the browser to 
                    cache previously entered form values entered by the user. 
                    For legitimate purposes, this allows the user to quickly 
                    re-enter the same data, when completing the form multiple 
                    times. When autocomplete is enabled on either/both the 
                    username password fields, this could allow a cyber-criminal 
                    with access to the victim's computer the ability to have the 
                    victims credentials autocomplete (automatically entered) as 
                    the cyber-criminal visits the affected page. Arachni has 
                    discovered that the response of the affected location 
                    contains a form containing a password field that has not 
                    disabled autocomplete.},
                severity:    Severity::LOW,
                remedy_guidance: %q{The autocomplete value can be configured in 
                    two different locations. The first location and most secure 
                    is to disable autocomplete attribute on the <FORM> HTML tag. 
                    This will therefor disable autocomplete for all inputs 
                    within that form. An example of disabling autocomplete 
                    within the form tag is '<FORM autocomplete=off>'. The second 
                    slightly less desirable option is to disable autocomplete 
                    attribute for a specific <INPUT> HTML tag itself. While this 
                    may be the less desired solution from a security 
                    perspective, it may be preferred method for usability 
                    reasons depending on size of the form. An example of 
                    disabling the autocomplete attribute within a password 
                    input tag is '<INPUT type=password autocomplete=off>'. Note, 
                    in these examples other <FORM> or <INPUT> attributes may be 
                    required.},
            },
            max_issues: 25
        }
    end

end
