=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Unvalidated redirect check.
#
# It audits links, forms and cookies, injects URLs and checks the `Location`
# header field to determine whether the attack was successful.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @see https://www.owasp.org/index.php/Top_10_2010-A10-Unvalidated_Redirects_and_Forwards
class Arachni::Checks::UnvalidatedRedirect < Arachni::Check::Base

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
        self.class.payload? url.to_s.split( '?' ).first
    end

    def self.options
        @options ||= {
            format: [ Format::STRAIGHT ],
            submit: {
                follow_location: false
            },

            # Add one more mutation (on the fly) which will include the original
            # value.
            each_mutation: proc do |mutation|
                next if !mutation.affected_input_value

                m = mutation.dup

                # Figure out the extension of the default value, if it has one.
                original_value = m.default_inputs[m.affected_input_name]

                # Null-terminate the injected value and append the ext.
                m.affected_input_value += "/?#{original_value}"

                # Pass our new mutation back to be audited.
                m
            end
        }
    end

    def run
        audit( self.class.payloads, self.class.options ) do |response, element|
            # If this was a sample/default value submission ignore it, we only
            # care about our payloads.
            next if !payload? element.seed

            # Simple check for straight HTTP redirection first.
            if payload? response.headers.location
                log vector: element, response: response
                next
            end

            # HTTP redirection check failed but if our payload ended up in the
            # response body it's worth loading it with a browser in case there's
            # a JS redirect.
            next if !response.body.include?( element.seed )

            with_browser( element, response, page, self.class.check_browser_result_cb )
        end
    end

    def self.check_browser_result( browser, element, response, referring_page )
        browser.load( response )

        return if !payload? browser.url

        log vector: element, response: response, referring_page: referring_page
    end

    def self.check_browser_result_cb
        @check_browser_result_cb ||= method(:check_browser_result)
    end

    def self.info
        {
            name:        'Unvalidated redirect',
            description: %q{
Injects URLs and checks the `Location` HTTP response header field and/or browser
URL to determine whether the attack was successful.
},
            elements:    ELEMENTS_WITH_INPUTS - [Element::LinkTemplate],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.2.5',

            issue:       {
                name:            %q{Unvalidated redirect},
                description:     %q{
Web applications occasionally use parameter values to store the address of the
page to which the client will be redirected -- for example:
`yoursite.com/page.asp?redirect=www.yoursite.com/404.asp`

An unvalidated redirect occurs when the client is able to modify the affected
parameter value in the request and thus control the location of the redirection.
For example, the following URL `yoursite.com/page.asp?redirect=www.anothersite.com`
will redirect to `www.anothersite.com`.

Cyber-criminals will abuse these vulnerabilities in social engineering attacks
to get users to unknowingly visit malicious web sites.

Arachni has discovered that the server does not validate the parameter value prior
to redirecting the client to the injected value.
},
                references:  {
                    'OWASP Top 10 2010' => 'https://www.owasp.org/index.php/Top_10_2010-A10-Unvalidated_Redirects_and_Forwards'
                },
                tags:            %w(unvalidated redirect injection header location),
                cwe:             819,
                severity:        Severity::MEDIUM,
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
