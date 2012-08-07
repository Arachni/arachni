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
# XSS in path audit module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.8
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
#
class Arachni::Modules::XSSPath < Arachni::Module::Base

    def self.tag
        @tag ||= 'my_tag_' + seed
    end

    def self.string
        @string ||= '<' + tag + '/>'
    end

    def self.requests
        @requests ||= [
            [ string, {} ],
            [ '>"\'>' + string, {} ],

            [ '', { string => '' } ],
            [ '', { '>"\'>' + string => '' } ],

            [ '', { '' => string } ],
            [ '', { '' => '>"\'>' + string } ]
        ]
    end

    def run
        path = get_path( page.url )

        return if audited?( path )
        audited( path )

        self.class.requests.each do |str, params|
            url  = path + str

            print_status( "Checking for: #{url}" )

            http.get( url, remove_id: true, params: params ) { |res| check_and_log( res, str ) }
        end
    end

    def check_and_log( res, str )
        # check for the existence of the tag name in the response before
        # parsing to verify, no reason to waste resources...
        return if !res.body || !res.body.include?( self.class.string )

        # see if we managed to successfully inject our element
        return if Nokogiri::HTML( res.body ).css( self.class.tag ).empty?

        log( { element: Element::PATH, injected: str }, res )
    end


    def self.info
        {
            name:        'XSSPath',
            description: %q{Cross-Site Scripting module for path injection},
            elements:    [ Element::PATH ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.8',
            references:  {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            targets:     %w(Generic),
            issue:       {
                name:            %q{Cross-Site Scripting (XSS) in path},
                description:     %q{Client-side code, like JavaScript, can
    be injected into the web application.},
                tags:            %w(xss path injection regexp),
                cwe:             '79',
                severity:        Severity::HIGH,
                cvssv2:          '9.0',
                remedy_guidance: %q{Path must be validated and filtered
before being returned as part of the HTML code of a page.}
            }

        }
    end

end
