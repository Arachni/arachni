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

#
# Mixed Resource detection module
#
# Looks for resources served over HTTP when the HTML code is server over HTTPS.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.3
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
            version:     '0.1.2',
            references:  {
                'Google Online Security Blog' =>
                    'http://googleonlinesecurity.blogspot.com/2011/06/trying-to-end-mixed-scripting.html'
            },
            targets:     %w(Generic),
            issue:       {
                name:            %q{Mixed Resource},
                description:     %q{Serving resources over an unencrypted channel
    while the HTML code is served over HTTPS can lead to
    Man-In-The-Middle attacks and provide a false sense of security.},
                tags:            %w(unencrypted resource javascript stylesheet),
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{Configure server to serve resources over the encrypted channel.}
            }

        }
    end

end
