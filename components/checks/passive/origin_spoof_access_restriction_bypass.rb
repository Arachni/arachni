=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Arachni::Checks::OriginSpoofAccessRestrictionBypass < Arachni::Check::Base

    HEADERS = [
        'X-Forwarded-For',
        'X-Originating-IP',
        'X-Remote-IP',
        'X-Remote-Addr'
    ]

    ADDRESS = '127.0.0.1'

    def self.http_options
        @http_options ||= {
            headers: HEADERS.inject({}) { |h, header| h.merge( header => ADDRESS ) }
        }
    end

    def run
        return if ![401, 403].include?( page.code )

        http.get( page.url, self.class.http_options, &method(:check_and_log) )
    end

    def check_and_log( response )
        return if response.code != 200

        log vector: Element::Server.new( response.url ), response: response
        print_ok "Request was accepted: #{response.url}"
    end

    def self.info
        {
            name:        'Origin Spoof Access Restriction Bypass',
            description: %q{Retries denied requests with a spoofed origin header
                to trick the web application into thinking that the request originated
                from localhost and checks whether the restrictions was bypassed.},
            elements:    [ Element::Server ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',

            issue:       {
                name:        %q{Access restriction bypass via origin spoof},
                description: %q{Access restrictions can be bypassed by tricking
                    the web application into thinking that the request originated
                    from localhost.},
                tags:        %w(access restriction server bypass),
                severity:    Severity::HIGH
            }
        }
    end

end
