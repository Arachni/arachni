=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Session fixation check.
#
# It identifies the session cookie by iterating through all cookies in the
# cookie-jar and performing login checks with each cookie removed.
# The session cookie is the one which results in a failed check.
#
# It then injects a taint via all page links and forms and checks whether or
# not the taint ended-up in the session cookie's value.
# If so, the webapp is vulnerable.
#
# The check requires a login-check and a valid, logged-in session.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1.3
class Arachni::Checks::SessionFixation < Arachni::Check::Base

    def token
        "_arachni_sf_#{random_seed}"
    end

    def run
        if !session.has_login_check?
            print_info 'No login-check has been set, cannot continue.'
            return
        end

        session.logged_in? do |logged_in|
            if !logged_in
                print_bad 'We seem to have been logged out, cannot continue'
                next
            end

            session.cookie do |cookie|
                name = cookie.name
                print_info "Found session cookie named: #{name}"

                audit(
                    token,
                    with_raw_parameters: false,
                    submit: {
                        response_max_size: 0
                    }
                ) do |response, element|
                    cookie = cookies_from_response( response ).
                        select { |c| c.name == name }.first
                    next if !cookie || !cookie.value.include?( token )

                    log(
                        vector:   element,
                        response: response,
                        proof:    cookie.source
                    )
                end
            end
        end
    end

    def self.info
        {
            name:        'Session fixation',
            description: %q{
Checks whether or not the session cookie can be set to an arbitrary value.
},
            elements:    [ Element::Form, Element::Link, Element::LinkTemplate ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.2',

            issue:       {
                name:        %q{Session fixation},
                description: %q{
HTTP by itself is a stateless protocol; therefore, the server is unable to
determine which requests are performed by which client and which clients are
authenticated or unauthenticated.

The use of HTTP cookies within the headers allows a web server to identify each
individual client and can thus determine which clients hold valid authentication
from those that do not.
These are known as session cookies or session tokens.

To prevent clients from being able to guess each other's session token, each
assigned session token should be entirely random and be different whenever a
session is established with the server.

Session fixation occurs when the client is able to specify their own session
token value and the value of the session cookie is not changed by the server
after successful authentication.
Occasionally, the session token will also remain unchanged for the user independently
of how many times they have authenticated.

Cyber-criminals will abuse this functionality by sending crafted URL links with a
predetermined session token within the link. The cyber-criminal will then wait
for the victim to login and become authenticated.
If successful, the cyber-criminal will know a valid session ID and therefore have
access to the victim's session.

Arachni has discovered that it is able to set its own session token.
},
                references:  {
                    'OWASP - Session fixation' => 'https://www.owasp.org/index.php/Session_fixation',
                    'WASC'  => 'http://projects.webappsec.org/w/page/13246960/Session%20Fixation'
                },
                tags:        %w(session cookie injection fixation hijacking),
                cwe:         384,
                severity:    Severity::HIGH,
                remedy_guidance: %q{
The most important remediation action is to prevent the server from accepting
client supplied data as session tokens.

Additionally, the client's session token should be changed at specific key stages
of the application flow, such as during authentication. This will ensure that even
if clients are able to set their own cookie, it will not persist into an authenticated
session.
}
            }
        }
    end

end
