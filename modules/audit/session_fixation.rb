=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
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
