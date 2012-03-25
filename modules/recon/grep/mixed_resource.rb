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
# Mixed Resource detection module
#
# Looks for resources served over HTTP when the HTML code is server over HTTPS.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.1.1
#
# @see http://googleonlinesecurity.blogspot.com/2011/06/trying-to-end-mixed-scripting.html
#
class MixedResource < Arachni::Module::Base

    def prepare
        @@__audited ||= Set.new
    end

    def run
        return if !https?( @page.url )

        print_status( 'Checking...' )

        doc = Nokogiri::HTML( @page.html )
        doc.xpath( './/script' ).each {
            |script|

            url = script.attributes['src'].to_s
            next if !url || https?( url ) || url.empty?

            log_resource( url )
        }

        doc.xpath( './/link' ).each {
            |script|

            url = script.attributes['href'].to_s
            if !url || !script.attributes['rel'].to_s.downcase == 'stylesheet' ||
                https?( url ) || url.empty?
                next
            end

            log_resource( url )
        }
    end

    def https?( url )
        URI( url ).scheme == 'https'
    end

    def log_resource( url )
        return if @@__audited.include?( url )

        @@__audited << url

        match_and_log( url )
    end

    def self.info
        {
            :name           => 'Mixed Resource',
            :description    => %q{Looks for resources served over HTTP when the HTML code is server over HTTPS.},
            :elements       => [
                Issue::Element::BODY
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1.1',
            :references     => {
                'Google Online Security Blog' =>
                    'http://googleonlinesecurity.blogspot.com/2011/06/trying-to-end-mixed-scripting.html'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Mixed Resource},
                :description => %q{Serving resources over an unencrypted channel
                    while the HTML code is served over HTTPS can lead to
                    Man-In-The-Middle attacks and provide a false sense of security.},
                :tags        => [ 'unencrypted', 'resource', 'javascript', 'stylesheet' ],
                :severity    => Issue::Severity::MEDIUM,
            }

        }
    end

end
end
end
