=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Allowed HTTP methods recon check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2
#
# @see http://en.wikipedia.org/wiki/WebDAV
# @see http://www.webdav.org/specs/rfc4918.html
class Arachni::Checks::AllowedMethods < Arachni::Check::Base

    def self.ran?
        !!@ran
    end

    def self.ran
        @ran = true
    end

    def run
        return if self.class.ran?

        print_status 'Checking...'
        http.request( page.url, method: :options ) { |response| check_and_log( response ) }
    end

    def clean_up
        self.class.ran
    end

    def check_and_log( response )
        methods = response.headers['Allow']
        return if !methods || methods.empty?

        log vector: Element::Server.new( response.url ), proof: methods,
            response: response

        # inform the user that we have a match
        print_ok( methods )
    end

    def self.info
        {
            name:        'Allowed methods',
            description: %q{Checks for supported HTTP methods.},
            elements:    [Element::Server],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.4',

            issue:       {
                name:            %q{Allowed HTTP methods},
                description:     %q{The webserver claims that it supports the logged methods.},
                references:  {
                    'Apache.org' => 'http://httpd.apache.org/docs/2.2/mod/core.html#limitexcept'
                },
                tags:            %w(http methods options),
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{Configure your web server to disallow unnecessary HTTP method.}
            }
        }
    end

end
