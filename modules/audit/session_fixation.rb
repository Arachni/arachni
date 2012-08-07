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
# @version 0.1
#
class Arachni::Modules::SessionFixation < Arachni::Module::Base

    def self.session_cookie=( name )
        @session_cookie = name
    end

    def self.session_cookie
        @session_cookie
    end

    def token
        '_arachni_sf_' + seed
    end

    def run
        if !framework.has_login_check?
            print_info 'No login-check has been set, cannot continue.'
            return
        end

        framework.logged_in? do |logged_in|
            if !logged_in
                print_bad 'We seem to have been logged out, cannot continue'
                next
            end

            find_session_cookie do |name|
                audit( token ) do |response, opts, _|
                    cookie = cookies_from_response( response ).select { |c| c.name == name }.first
                    next if !cookie || !cookie.value.include?( token )
                    log( opts, response )
                end
            end
        end
    end

    def find_session_cookie( &block )
        return block.call( self.class.session_cookie ) if self.class.session_cookie

        http.cookies.each do |cookie|
            framework.logged_in?( cookies: { cookie.name => '' } ) do |bool|
                next if bool
                print_info "Found session cookie named: #{cookie.name}"
                block.call( self.class.session_cookie = cookie.name )
            end
        end
    end

    def self.info
        {
            name:        'Session fixation',
            description: %q{Checks whether or not the session cookie can be set to an arbitrary value.},
            elements:    [ Element::FORM, Element::LINK ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            references:  {
                 'OWASP - Session fixation' => 'hhttps://www.owasp.org/index.php/Session_fixation'
             },
            targets:     %w(Generic),
            issue:       {
                name:        %q{Session fixation},
                description: %q{The web application allows the session ID to be fixed by a 3rd party.},
                tags:        %w(session cookie injection fixation hijacking),
                cwe:         '384',
                severity:    Severity::HIGH
            }
        }
    end

end
