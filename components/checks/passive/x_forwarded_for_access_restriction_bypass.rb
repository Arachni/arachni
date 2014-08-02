=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Arachni::Checks::XForwardedAccessRestrictionBypass < Arachni::Check::Base

    def run
        return if ![401, 403].include?( page.code )
        http.get( page.url, headers: { 'X-Forwarded-For' => '127.0.0.1' } ) do |res|
            check_and_log( res )
        end
    end

    def check_and_log( response )
        return if response.code != 200
        log vector: Element::Server.new( response.url ), response: response
        print_ok "Request was accepted: #{response.url}"
    end

    def self.info
        {
            name:        'X-Forwarded-For Access Restriction Bypass',
            description: %q{Retries denied requests with a X-Forwarded-For header
                to trick the web application into thinking that the request originates
                from localhost and checks whether the restrictions was bypassed.},
            elements:    [ Element::Server ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',

            issue:       {
                name:        %q{Access restriction bypass via X-Forwarded-For},
                description: %q{Access restrictions can be bypassed by tricking
                    the web application into thinking that the request originated
                    from localhost.},
                tags:        %w(access restriction server bypass),
                severity:    Severity::HIGH
            }
        }
    end

end
