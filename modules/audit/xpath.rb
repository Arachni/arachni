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
# XPath Injection audit module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.4
#
# @see http://cwe.mitre.org/data/definitions/91.html
# @see http://www.owasp.org/index.php/XPATH_Injection
# @see http://www.owasp.org/index.php/Testing_for_XPath_Injection_%28OWASP-DV-010%29
#
class Arachni::Modules::XPathInjection < Arachni::Module::Base

    def self.error_strings
        @error_strings ||= read_file( 'errors.txt' )
    end

    # These will hopefully cause the webapp to output XPath error messages.
    def self.payloads
        @payloads ||= %w('" ]]]]]]]]] <!--)
    end

    def self.options
        @options ||= { format: [Format::APPEND], substring: error_strings }
    end

    def run
        audit self.class.payloads, self.class.options
    end

    def self.info
        {
            name:        'XPath Injection',
            description: %q{XPath injection module},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.4',
            references:  {
                'OWASP' => 'http://www.owasp.org/index.php/XPATH_Injection',
                'WASC' => 'http://projects.webappsec.org/w/page/13247005/XPath%20Injection'
            },
            targets:     %w(General PHP Java dotNET libXML2),
            issue:       {
                name:            %q{XPath Injection},
                description:     %q{XML Path Language (XPath) queries are used 
                    by web applications for selecting nodes from XML documents. 
                    Once selected, the value of these nodes can then be used by 
                    the application. A simple example for the use of XML 
                    documents is to store user information. As part of the 
                    authentication process, the application will perform an 
                    XPath query to confirm the login credentials and retrieve 
                    that user's information to use in the following request. 
                    XPath injection occurs where untrusted data is used to build 
                    the XPath query. Cyber-criminals may abuse this injection 
                    vulnerability to bypass authentication, query other user's 
                    information, or if the XML document contains privileged user 
                    credentials may allow the cyber-criminal to escalate their 
                    privileges. Arachni injected XPath queries into the page, 
                    and based off the responses from the server has discovered 
                    the page is vulnerable to XPath injection.},
                tags:            %w(xpath database error injection regexp),
                cwe:             '91',
                severity:        Severity::HIGH,
                remedy_guidance: %q{The preferred way to protect against XPath 
                    injection is to utilise parametized (also known as prepared) 
                    XPath queries. When utilising this method of querying the 
                    XML document any value supplied by the client will be 
                    handled as a string rather than part of the XPath query. An 
                    alternative to parametized queries it to use precompiled 
                    XPath queries. Precompiled XPath queries are not generated 
                    dynamically and will therefor never process user supplied 
                    input as XPath. Depending on the framework being used, 
                    implementation of parametized queries or precompiled queries 
                    will differ. Depending on the framework being used by the 
                    application parametized queries and/or precompiled queries 
                    may not be possible. In this case, input filtering on all 
                    untrusted input should occur to ensure that it is not 
                    included as part of the query.},
            }
        }
    end

end
