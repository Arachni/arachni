=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::HtaccessLimit < Arachni::Check::Base

    def run
        return if page.code != 401

        [:post, :head, :blah]. each do |m|
            http.request( page.url, method: m ) { |response| check_and_log( response ) }
        end
    end

    def check_and_log( response )
        return if response.code != 200

        log(
            vector:   Element::Server.new( response.url ),
            response: response,
            proof:    response.status_line
        )
        print_ok "Request was accepted: #{response.url}"
    end

    def self.info
        {
            name:        '.htaccess LIMIT misconfiguration',
            description: %q{Checks for misconfiguration in LIMIT directives that blocks
                GET requests but allows POST.},
            elements:    [ Element::Server ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.7',

            issue:       {
                name:        %q{Misconfiguration in LIMIT directive of .htaccess file},
                description: %q{
There are a number of HTTP methods that can be used on a webserver (for example
`OPTIONS`, `HEAD`, `GET`, `POST`, `PUT`, `DELETE `etc.).
Each of these methods perform a different function, and each has an associated
level of risk when their use is permitted on the webserver.

The `<Limit>` directive within Apache's `.htaccess` file allows administrators
to define which of the methods they would like to block. However, as this is a
blacklisting approach, it is inevitable that a server administrator may
accidentally miss adding certain HTTP methods to be blocked, thus increasing
the level of risk to the application and/or server.
},
                references: {
                    'Apache.org' => 'http://httpd.apache.org/docs/2.2/mod/core.html#limit'
                },
                tags:        %w(htaccess server limit),
                severity:    Severity::HIGH,
                remedy_guidance:  %q{
The preferred configuration is to prevent the use of unauthorised HTTP methods
by utilising the `<LimitExcept>` directive.

This directive uses a whitelisting approach to permit HTTP methods while
blocking all others not listed in the directive, and will therefor block any
method tampering attempts.

Most commonly, the only HTTP methods required for most scenarios are `GET` and
`POST`. An example of permitting these HTTP methods is:
 `<LimitExcept POST GET> require valid-user </LimitExcept>`
}
            }
        }
    end

end
