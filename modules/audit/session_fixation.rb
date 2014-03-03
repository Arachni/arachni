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

# Session fixation module.
#
# It identifies the session cookie by iterating through all cookies in the
# cookie-jar and performing login checks with each cookie removed.
# The session cookie is the one which results in a failed check.
#
# It then injects a taint via all page links and forms and checks whether or
# not the taint ended-up in the session cookie's value.
# If so, the webapp is vulnerable.
#
# The module requires a login-check and a valid, logged-in session.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
class Arachni::Modules::SessionFixation < Arachni::Module::Base

    def token
        '_arachni_sf_' + seed
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

                audit( token ) do |response, opts, _|
                    cookie = cookies_from_response( response ).select { |c| c.name == name }.first
                    next if !cookie || !cookie.value.include?( token )
                    log( opts, response )
                end
            end
        end
    end

    def self.info
        {
            name:        'Session fixation',
            description: %q{Checks whether or not the session cookie can be set to an arbitrary value.},
            elements:    [ Element::FORM, Element::LINK ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.1',
            references:  {
                 'OWASP' => 'https://www.owasp.org/index.php/Session_fixation',
                 'WASC'  => 'http://projects.webappsec.org/w/page/13246960/Session%20Fixation'
             },
            targets:     %w(Generic),
            issue:       {
                name:        %q{Session fixation},
                description: %q{HTTP by itself is a stateless protocol. Therefore
                    the server is unable to determine which requests are 
                    performed by which client, and which clients are 
                    authenticated or unauthenticated. The use of HTTP cookies 
                    within the headers, allows a web server to identify each 
                    individual client, and can therefore determine which clients
                    hold valid authentication from those that do not. These are 
                    known as session cookies or session tokens. To prevent 
                    clients from being able to guess each other's session token, 
                    each assigned session token should be entirely random, and 
                    be different whenever a session is established with the 
                    server. Session fixation occurs when the client is able to 
                    specify their own session token value, and the value of the 
                    session cookie is not changed by the server after successful 
                    authentication. Occasionally the session token will also 
                    remain unchanged for the user independently of how many times
                    they have authenticated. Cyber-criminals will abuse this 
                    functionality by sending crafted URL links with a 
                    predetermined session token within the link. The cyber-
                    criminal will then wait for the victim to login and become 
                    authenticated. If successful the cyber-criminal will know a 
                    valid session ID, and therefore have access to the victim's
                    session. Arachni has discovered that it is able to set its 
                    own session token, and during the login process remains 
                    unchanged.},
                tags:        %w(session cookie injection fixation hijacking),
                cwe:         '384',
                severity:    Severity::HIGH,
                remedy_guidance: %q{The most important remediation action is to 
                    prevent the server accepting client supplied tokens through 
                    either a GET or POST request. Additionally, the client's
                    session token should be changed at specific key stages of 
                    the application flow, such as during authentication. This 
                    will ensure that even if clients are able to set their own 
                    cookie, it will not persist into an authenticated session. 
                },
            }
        }
    end

end
