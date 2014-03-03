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

#
# Allowed HTTP methods recon module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.5
#
# @see http://en.wikipedia.org/wiki/WebDAV
# @see http://www.webdav.org/specs/rfc4918.html
#
class Arachni::Modules::AllowedMethods < Arachni::Module::Base

    def self.ran?
        !!@ran
    end

    def self.ran
        @ran = true
    end

    def run
        return if self.class.ran?

        print_status( "Checking..." )
        http.request( page.url, method: :options ) { |res| check_and_log( res ) }
    end

    def clean_up
        self.class.ran
    end

    def check_and_log( res )
        methods = res.headers_hash['Allow']
        return if !methods || methods.empty?

        log( { element: Element::SERVER, match: methods }, res )

        # inform the user that we have a match
        print_ok( methods )
    end

    def self.info
        {
            name:        'Allowed methods',
            description: %q{Checks for supported HTTP methods.},
            elements:    [Element::SERVER],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.5',
            targets:     %w(Generic),
            references:  {
                'Apache.org' => 'http://httpd.apache.org/docs/2.2/mod/core.html#limitexcept'
            },
            issue:       {
                name:            %q{Allowed HTTP methods},
                description:     %q{There are a number of HTTP methods that can 
                    be used on a webserver, for example OPTIONS, HEAD, GET, 
                    POST, PUT, DELETE etc.  Each of these methods perform a 
                    different function, and each have an associate level of risk 
                when their use is permitted on the webserver. A client can use 
                    the OPTION method within a request to query a server to 
                    determine which methods are allowed. Cyber-criminals will 
                    almost always perform this simple test as it will give a 
                    very quick indication of any risk methods being permitted by 
                    the server. Arachni discovered that several methods 
                    supported by the server.},
                tags:            %w(http methods options),
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{It is recommended that a whitelisting 
                    approach be taken to explicitly permit the HTTP methods required
                    by the application and block all others.
                    Typically the only HTTP methods required for most 
                    applications are the GET and POST . All other
                    methods perform actions that are rarely required, or perform 
                    actions that are inherently risky. These risky methods (such 
                    as PUT, DELETE, etc) should be protected by strict 
                    limitations such as ensuring that the channel is secure 
                    (SSL/TLS enabled), and only authorised and trusted clients 
                    are permitted to use them.}
            }
        }
    end

end
