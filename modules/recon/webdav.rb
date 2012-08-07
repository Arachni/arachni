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
# WebDAV detection recon module.
#
# It doesn't check for a functional DAV implementation but uses the
# OPTIONS HTTP method to see if 'PROPFIND' is allowed.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.4
#
# @see http://en.wikipedia.org/wiki/WebDAV
# @see http://www.webdav.org/specs/rfc4918.html
#
class Arachni::Modules::WebDav < Arachni::Module::Base

    def self.dav_method
        @check ||= 'PROPFIND'
    end

    def self.found?
        @found ||= false
    end

    def self.found
        @found = true
    end

    def run
        path = get_path( page.url )
        return if self.class.found? || audited?( path )

        http.request( path, method: :options, remove_id: true ) { |res| check_and_log( res ) }
        audited( path )
    end

    def self.info
        {
            name:        'WebDav',
            description: %q{Checks for WebDAV enabled directories.},
            elements:    [ Element::SERVER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.4',
            references:  {
                'WebDAV.org' => 'http://www.webdav.org/specs/rfc4918.html',
                'Wikipedia'  => 'http://en.wikipedia.org/wiki/WebDAV',
            },
            targets:     %w(Generic),
            issue:       {
                name:             %q{WebDAV},
                description:      %q{WebDAV is enabled on the server.
    Consider auditing further using a specialised tool.},
                tags:             %w(webdav options methods server),
                severity:         Severity::INFORMATIONAL,
                remedy_guidance:  %q{Disable WebDAV if not required. If it is required, perform audit using specialized tools.}
            }

        }
    end

    def check_and_log( res )
        begin
            allowed = res.headers_hash['Allow'].split( ',' ).map { |method| method.strip }
            return if !allowed.include?( self.class.dav_method )
        rescue
            return
        end

        self.class.found

        log( { element: Element::SERVER }, res )
        print_ok "Enabled for: #{res.effective_url}"
    end

end
