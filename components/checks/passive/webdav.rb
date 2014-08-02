=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# WebDAV detection recon check.
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
class Arachni::Checks::WebDav < Arachni::Check::Base

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

        http.request( path, method: :options ) { |response| check_and_log( response ) }
        audited( path )
    end

    def check_and_log( response )
        begin
            allowed = response.headers['Allow'].split( ',' ).map { |method| method.strip }
            return if !allowed.include?( self.class.dav_method )
        rescue
            return
        end

        self.class.found

        log(
             proof:    response.headers['Allow'],
             vector:   Element::Server.new( response.url ),
             response: response
        )
        print_ok "Enabled for: #{response.url}"
    end

    def self.info
        {
            name:        'WebDAV',
            description: %q{Checks for WebDAV enabled directories.},
            elements:    [ Element::Server ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.4',

            issue:       {
                name:            %q{WebDAV},
                description:     %q{WebDAV is enabled on the server.
    Consider auditing further using a specialised tool.},
                references:  {
                    'WebDAV.org' => 'http://www.webdav.org/specs/rfc4918.html',
                    'Wikipedia'  => 'http://en.wikipedia.org/wiki/WebDAV',
                },
                tags:            %w(webdav options methods server),
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{Disable WebDAV if not required. If it is required, perform an audit using specialized tools.}
            }

        }
    end

end
