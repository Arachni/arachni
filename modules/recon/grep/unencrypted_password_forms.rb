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

    def determine_name( input )
        input['name'] || input['id']
    end

    def password?( input )
        input['type'].to_s.downcase == 'password'
    end

    def check_form?( form )
        uri_parse( form.action ).scheme.downcase == 'http' && form.raw['auditable']
    end

    def run
        page.forms.each { |form| check_and_log( form ) }
    end

    def check_and_log( form )
        return if !check_form?( form )

        form.raw['auditable'].each do |input|
            name = determine_name( input )
            next if !password?( input ) || audited?( input ) || !name

            log( var: name, match: form.to_html, element: Element::FORM )

            print_ok( "Found unprotected password field '#{name}' at #{page.url}" )
            audited( input )
        end
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
                'OWASP Top 10 2010' => 'http://www.owasp.org/index.php/Top_10_2010-A9-Insufficient_Transport_Layer_Protection',
                'OWASP' => 'www.owasp.org/index.php/Transport_Layer_Protection_Cheat_Sheet',
                'WASC' => 'http://projects.webappsec.org/w/page/13246945/Insufficient%20Transport%20Layer%20Protection'
            },
            targets:     %w(Generic),
            issue:       {
                name:            %q{Unencrypted password form},
                description:     %q{The HTTP protocol by itself is clear text, 
                    meaning that any data that is transmitted via HTTP can be 
                    captured and the contents viewed. To keep data private, and 
                    prevent it from being intercepted HTTP is often tunnelled 
                    through either Secure Sockets Layer (SSL), or Transport 
                    Layer Security (TLS). When either of these encryption 
                    standards are used it is referred to as HTTPS. Cyber-
                    criminals will often attempt to compromise credentials 
                    passed from the client to the server using HTTP. This can be 
                    conducted via various different Man in The Middle (MiTM) 
                    attacks or through network packet captures. Arachni 
                    discovered that the affected page contains a 'password' 
                    input, however the value of the field is not sent to the 
                    server utilising HTTPS. Therefor it is possible that any 
                    submitted credential may become compromised.},
                tags:            %w(unencrypted password form),
                cwe:             '319',
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{The affected site should be secured 
                    utilising the latest and most secure encryption protocols. 
                    These include SSL version 3.0 and TLS version 1.2. While 
                    TLS 1.2 is the latest and the most preferred protocol, not 
                    all browsers will support this encryption method. Therefor 
                    the more common SSL is included. Older protocols such as SSL 
                    version 2, and weak ciphers (< 128 bit) should also be 
                    disabled. References for framework specific remediation and 
                    best practices can be obtained from 
                    'www.owasp.org/index.php/Transport_Layer_Protection_Cheat_Sheet'}
            }

        }
    end

end
