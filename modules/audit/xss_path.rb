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

# XSS in path audit module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.10
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
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

            http.get( url, params: params ) { |res| check_and_log( res, str ) }
        end
    end

    def check_and_log( res, str )
        # check for the existence of the tag name in the response before
        # parsing to verify, no reason to waste resources...
        return if !res.body || !res.body.downcase.include?( self.class.string )

        # see if we managed to successfully inject our element
        return if Nokogiri::HTML( res.body ).css( self.class.tag ).empty?

        log( { element: Element::PATH, injected: str }, res )
    end


    def self.info
        {
            name:        'XSS in path',
            description: %q{Cross-Site Scripting module for path injection},
            elements:    [ Element::PATH ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.10',
            references:  {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/',
                'WASC' => 'http://projects.webappsec.org/w/page/13246920/Cross%20Site%20Scripting',
                'OWASP' => 'www.owasp.org/index.php/XSS_%28Cross_Site_Scripting%29_Prevention_Cheat_Sheet'
            },
            targets:     %w(Generic),
            issue:       {
                name:            %q{Cross-Site Scripting (XSS) in path},
                description:     %q{Client side scripts are used extensively by 
                    modern web applications. They perform simple functions such 
                    as the formatting of text to full manipulation of client 
                    side data and operating system interaction. Cross Site 
                    Scripting (XSS) is where the client is able to inject 
                    scripts into a request and have the server return the script 
                    to the client. This occurs because the application is taking 
                    untrusted data (in this example from the client) and reusing 
                    it without performing any data validation or sanitisation. 
                    If the injected script is returned immediately this is known 
                    as reflected XSS. If the injected script is stored by the 
                    server and returned to any client visiting the affected page 
                    then this is known as persistent XSS (also stored XSS). A 
                    common attack used by cyber-criminals is to steal a client's 
                    session token by injecting JavaScript, however XSS 
                    vulnerabilities can also be abused to exploit clients for 
                    example by visiting the page either directly or through a 
                    crafted HTTP link delivered via a social engineering email. 
                    Note: many modern browsers attempt to implement some form of 
                    XSS protection, however these do not protect against all 
                    methods of attack, and in some cases can easily be bypassed. 
                    Arachni has discovered that it is possible to insert script 
                    content directly into the requests PATH, or within a request 
                    header, and have it returned in the server's response. For 
                    example 'HTTP://yoursite.com/INJECTION_HERE/' or 
                    'referer: HTTP://yoursite.com/INJECTION_HERE' where 
                    INJECTION_HERE represents the location where the Arachni 
                    payload was injected.},
                tags:            %w(xss path injection regexp),
                cwe:             '79',
                severity:        Severity::HIGH,
                cvssv2:          '9.0',
                remedy_guidance: %q{To remediate XSS vulnerabilities it is 
                    important to never use untrusted or unfiltered data within 
                    the code of a HTML page. Untrusted data can originate not 
                    only form the client but potentially a third party, or 
                    previously uploaded file etc. Filtering of untrusted data 
                    typically involves converting special characters to their 
                    HTML entity encoding equivalent (however other methods do 
                    exist. see ref.). These special characters include (ignoring 
                    commas) '&, <, >, ", ', /'. An example of HTML entity encode 
                    is converting a '<' to '&lt;'. Although it is possible to 
                    filter untrusted input, there are five locations within a 
                    HTML page where untrusted input (even if it has been 
                    filtered) should never be placed. These locations include 1. 
                    Directly in a script. 2. inside a HTML comment. 3. in an 
                    attribute name. 4. in a tag name. 5. Directly in CSS. Where 
                    untrusted data is inserted into HTML element content, HTML 
                    common attributes, JavaScript data values, JSON values, HTML 
                    style property values, or HTML URL parameter values it must 
                    be filtered. Each of these locations have their own form of 
                    escaping and filtering.
                    Because many browsers attempt to implement XSS protection, 
                    any manual verification of this finding should be conducted 
                    utilising multiple different browsers and browser versions.}
            }

        }
    end

end
