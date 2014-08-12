=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# Allowed HTTP methods recon check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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
            version:     '0.2',

            issue:       {
                name:            %q{Allowed HTTP methods},
                description:     %q{
There are a number of HTTP methods that can be used on a webserver (`OPTIONS`,
`HEAD`, `GET`, `POST`, `PUT`, `DELETE `etc.).  Each of these methods perform a
different function and each have an associated level of risk when their use is
permitted on the webserver.

A client can use the `OPTION` method within a request to query a server to
determine which methods are allowed.

Cyber-criminals will almost always perform this simple test as it will give a
very quick indication of any risk methods being permitted by the server.

Arachni discovered that several methods supported by the server.
},
                references:  {
                    'Apache.org' => 'http://httpd.apache.org/docs/2.2/mod/core.html#limitexcept'
                },
                tags:            %w(http methods options),
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{
It is recommended that a whitelisting approach be taken to explicitly permit the
HTTP methods required by the application and block all others.

Typically the only HTTP methods required for most applications are the `GET`
and `POST`. All other methods perform actions that are rarely required, or
perform actions that are inherently risky.

These risky methods (such as `PUT`, `DELETE`, etc) should be protected by strict
limitations such as ensuring that the channel is secure (SSL/TLS enabled) and
only authorised and trusted clients are permitted to use them.
}
            }
        }
    end

end
