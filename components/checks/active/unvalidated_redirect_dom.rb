=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Unvalidated redirect DOM check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @see https://www.owasp.org/index.php/Top_10_2010-A10-Unvalidated_Redirects_and_Forwards
class Arachni::Checks::UnvalidatedRedirectDOM < Arachni::Check::Base

    BASE_URL = "www.#{Utilities.random_seed}.com"

    def self.payloads
        @payloads ||= [
            BASE_URL,
            "https://#{BASE_URL}",
            "http://#{BASE_URL}"
        ].map { |url| Arachni::URI( url ).to_s }
    end

    def self.payload?( url )
        (@set_payloads ||= Set.new( payloads )).include? Arachni::URI( url ).to_s
    end
    def payload?( url )
        self.class.payload? url
    end

    def self.options
        @options ||= {
            format:               [ Format::STRAIGHT ],
            parameter_names:      false,
            with_extra_parameter: false
        }
    end

    def run
        each_candidate_dom_element do |element|
            element.audit( self.class.payloads, self.class.options )
        end
    end

    def self.check_and_log( page, element )
        return if !payload? page.url
        log vector: element, page: page
    end

    def self.info
        {
            name:        'Unvalidated DOM redirect',
            description: %q{
Injects URLs and checks the browser URL to determine whether the attack was successful.
},
            elements:    DOM_ELEMENTS_WITH_INPUTS - [
                Element::LinkTemplate::DOM,
                Element::UIInput::DOM
            ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.3',

            issue:       {
                name:            %q{Unvalidated DOM redirect},
                description:     %q{
Web applications occasionally use DOM input values to store the address of the
page to which the client will be redirected -- for example:
`yoursite.com/#/?redirect=www.yoursite.com/404.asp`

An unvalidated redirect occurs when the client is able to modify the affected
parameter value and thus control the location of the redirection.
For example, the following URL `yoursite.com/#/?redirect=www.anothersite.com`
will redirect to `www.anothersite.com`.

Cyber-criminals will abuse these vulnerabilities in social engineering attacks
to get users to unknowingly visit malicious web sites.

Arachni has discovered that the web page does not validate the parameter value prior
to redirecting the client to the injected value.
},
                references:  {
                    'OWASP Top 10 2010' => 'https://www.owasp.org/index.php/Top_10_2010-A10-Unvalidated_Redirects_and_Forwards'
                },
                tags:            %w(unvalidated redirect dom injection),
                cwe:             819,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
The application should ensure that the supplied value for a redirect is permitted.
This can be achieved by performing whitelisting on the parameter value.

The whitelist should contain a list of pages or sites that the application is
permitted to redirect users to. If the supplied value does not match any value
in the whitelist then the server should redirect to a standard error page.
}
            }
        }
    end

end
