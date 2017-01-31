=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# XPath Injection check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://cwe.mitre.org/data/definitions/91.html
# @see https://www.owasp.org/index.php/XPATH_Injection
# @see https://www.owasp.org/index.php/Testing_for_XPath_Injection_%28OWASP-DV-010%29
class Arachni::Checks::XpathInjection < Arachni::Check::Base

    def self.error_strings
        @error_strings ||= read_file( 'errors.txt' )
    end

    # These will hopefully cause the webapp to output XPath error messages.
    def self.payloads
        @payloads ||= %w('" ]]]]]]]]] <!--)
    end

    def self.options
        @options ||= { format: [Format::APPEND], signatures: error_strings }
    end

    def run
        audit self.class.payloads, self.class.options
    end

    def self.info
        {
            name:        'XPath Injection',
            description: %q{XPath injection check},
            elements:    ELEMENTS_WITH_INPUTS,
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.6',

            issue:       {
                name:            %q{XPath Injection},
                description:     %q{
XML Path Language (XPath) queries are used by web applications for selecting
nodes from XML documents.
Once selected, the value of these nodes can then be used by the application.

A simple example for the use of XML documents is to store user information. As
part of the authentication process, the application will perform an XPath query
to confirm the login credentials and retrieve that user's information to use in
the following request.

XPath injection occurs where untrusted data is used to build XPath queries.

Cyber-criminals may abuse this injection vulnerability to bypass authentication,
query other user's information, or, if the XML document contains privileged user
credentials, allow the cyber-criminal to escalate their privileges.

Arachni injected special XPath query characters into the page and based on the
responses from the server, has determined that the page is vulnerable to XPath injection.
},
                references:  {
                    'OWASP' => 'https://www.owasp.org/index.php/XPATH_Injection',
                    'WASC' => 'http://projects.webappsec.org/w/page/13247005/XPath%20Injection'
                },
                tags:            %w(xpath database error injection regexp),
                cwe:             91,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
The preferred way to protect against XPath injection is to utilise parameterized
(also known as prepared) XPath queries.
When utilising this method of querying the XML document any value supplied by the
client will be handled as a string rather than part of the XPath query.

An alternative to parameterized queries it to use precompiled XPath queries.
Precompiled XPath queries are not generated dynamically and will therefor never
process user supplied input as XPath.
}
            }
        }
    end

end
