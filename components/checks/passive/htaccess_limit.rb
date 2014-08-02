=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.5
class Arachni::Checks::Htaccess < Arachni::Check::Base

    def run
        return if page.code != 401

        [:post, :head, :blah]. each do |m|
            http.request( page.url, method: m ) { |response| check_and_log( response ) }
        end
    end

    def check_and_log( response )
        return if response.code != 200

        log vector: Element::Server.new( response.url ), response: response
        print_ok "Request was accepted: #{response.url}"
    end

    def self.info
        {
            name:        '.htaccess LIMIT misconfiguration',
            description: %q{Checks for misconfiguration in LIMIT directives that blocks
                GET requests but allows POST.},
            elements:    [ Element::Server ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.5',

            issue:       {
                name:        %q{Misconfiguration in LIMIT directive of .htaccess file},
                description: %q{The .htaccess file blocks GET requests but allows POST.},
                references: {
                    'Apache.org' => 'http://httpd.apache.org/docs/2.2/mod/core.html#limit'
                },
                tags:        %w(htaccess server limit),
                severity:    Severity::HIGH,
                remedy_guidance:  %q{Do not use the LIMIT tag.
                    If you are in a situation where you want to allow specific request methods, you should use LimitExcept instead.}
            }
        }
    end

end
