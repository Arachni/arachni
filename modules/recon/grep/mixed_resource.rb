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
# Mixed Resource detection module
#
# Looks for resources served over HTTP when the HTML code is server over HTTPS.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.4
#
# @see http://googleonlinesecurity.blogspot.com/2011/06/trying-to-end-mixed-scripting.html
#
class Arachni::Modules::MixedResource < Arachni::Module::Base

    def run
        return if !https?( page.url )

        print_status( 'Checking...' )

        page.document.css( 'script' ).each do |script|
            url = script.attributes['src'].to_s
            log_resource( url ) if insecure_script?( script )
        end

        page.document.css( 'link' ).each do |script|
            url = script.attributes['href'].to_s
            log_resource( url ) if insecure_link?( script )
        end
    end

    def insecure_link?( script )
        url = script.attributes['href'].to_s
        url && !url.empty? && script.attributes['rel'].to_s.downcase == 'stylesheet' &&
            !https?( url )
    end

    def insecure_script?( script )
        url = script.attributes['src'].to_s
        url && !url.empty? && !https?( url )
    end

    def https?( url )
        uri_parse( to_absolute( url, page.url ) ).scheme == 'https'
    end

    def log_resource( url )
        return if audited?( url )
        audited( url )

        match_and_log( url )
    end

    def self.info
        {
            name:        'Mixed Resource',
            description: %q{Looks for resources served over HTTP when the HTML code is server over HTTPS.},
            elements:    [ Element::BODY ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.4',
            references:  {
                'Google Online Security Blog' =>
                    'http://googleonlinesecurity.blogspot.com/2011/06/trying-to-end-mixed-scripting.html',
                'WASC' => 'http://projects.webappsec.org/w/page/13246945/Insufficient%20Transport%20Layer%20Protection'
            },
            targets:     %w(Generic),
            issue:       {
                name:            %q{Mixed Resource},
                description:     %q{The HTTP protocol by itself is clear text, 
                    meaning that any data that is transmitted via HTTP can be 
                    captured and the contents viewed. To keep data private, and 
                    prevent it from being intercepted HTTP is often tunnelled 
                    through either Secure Sockets Layer (SSL), or Transport 
                    Layer Security (TLS). When either of these encryption 
                    standards are used it is referred to as HTTPS. Cyber-
                    criminals will often attempt to compromise sensitive 
                    information passed from the client to the server using HTTP. 
                    This can be conducted via various different Man in The 
                    Middle (MiTM) attacks or through network packet captures. 
                    Arachni discovered that the affected site is utilising both 
                    HTTP and HTTPS. While the HTML code is served over HTTPS, 
                    the server is also serving resources over an unencrypted 
                    channel which can lead to the compromise of data, while 
                    providing a false sense of security to the user. },
                tags:            %w(unencrypted resource javascript stylesheet),
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{All pages and/or resources on the affected 
                    site should be secured equally, utilising the latest and 
                    most secure encryption protocols. These include SSL version 
                    3.0 and TLS version 1.2. While TLS 1.2 is the latest and the 
                    most preferred protocol, not all browsers will support this 
                    encryption method. Therefor the more common SSL is included. 
                    Older protocols such as SSL version 2, and weak ciphers 
                    (< 128 bit) should also be disabled. References for 
                    framework specific remediation and best practices can be 
                    obtained from: 
                    'www.owasp.org/index.php/Transport_Layer_Protection_Cheat_Sheet'}
            }

        }
    end

end
