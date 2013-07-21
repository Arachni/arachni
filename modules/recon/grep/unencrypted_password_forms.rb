=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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
# Unencrypted password form
#
# Looks for password inputs that don't submit data over an encrypted channel (HTTPS).
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.7
#
# @see http://www.owasp.org/index.php/Top_10_2010-A9-Insufficient_Transport_Layer_Protection
#
class Arachni::Modules::UnencryptedPasswordForms < Arachni::Module::Base

    def run
        page.forms.each { |form| check_and_log( form ) }
    end

    def check_and_log( form )
        return if !check_form?( form )

        form.inputs.each do |name, v|
            next if form.field_type_for( name ) != :password || audited?( form.id )

            log( var: name, match: form.to_html, element: Element::FORM )

            print_ok( "Found unprotected password field '#{name}' at #{page.url}" )
            audited form.id
        end
    end

    def check_form?( form )
        uri_parse( form.action ).scheme.downcase == 'http'
    end

    def self.info
        {
            name:        'Unencrypted password forms',
            description: %q{Looks for password inputs that don't submit data
                over an encrypted channel (HTTPS).},
            elements:    [ Element::FORM ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.7',
            references:  {
                'OWASP Top 10 2010' => 'http://www.owasp.org/index.php/Top_10_2010-A9-Insufficient_Transport_Layer_Protection'
            },
            targets:     %w(Generic),
            issue:       {
                name:            %q{Unencrypted password form},
                description:     %q{Transmission of password does not use an encrypted channel.},
                tags:            %w(unencrypted password form),
                cwe:             '319',
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{Forms with sensitive content, like passwords, must be sent over HTTPS.}
            }

        }
    end

end
