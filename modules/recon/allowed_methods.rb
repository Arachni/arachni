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
# Allowed HTTP methods recon module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.4
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
        http.request( page.url, method: :options, remove_id: true ) { |res| check_and_log( res ) }
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
            name:        'AllowedMethods',
            description: %q{Checks for supported HTTP methods.},
            elements:    [Element::SERVER],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.4',
            references:  {
                  'Apache.org' => 'http://httpd.apache.org/docs/2.2/mod/core.html#limitexcept'
            },
            targets:     %w(Generic),
            issue:       {
                name:            %q{Allowed HTTP methods},
                description:     %q{The webserver claims that it supports the logged methods.},
                tags:            %w(http methods options),
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{Configure your web server properly to disallow unnecessary HTTP method.}
            }
        }
    end

end
