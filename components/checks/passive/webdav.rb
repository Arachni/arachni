=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# WebDAV detection recon check.
#
# It doesn't check for a functional DAV implementation but uses the
# OPTIONS HTTP method to see if 'PROPFIND' is allowed.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://en.wikipedia.org/wiki/WebDAV
# @see http://www.webdav.org/specs/rfc4918.html
class Arachni::Checks::Webdav < Arachni::Check::Base

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
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.5',

            issue:       {
                name:            %q{WebDAV},
                description:     %q{
Web Distributed Authoring and Versioning (WebDAV) is a facility that enables
basic file management (reading and writing) to a web server. It essentially allows
the webserver to be mounted by the client as a traditional file system allowing
users a very simplistic means to access it as they would any other medium or
network share.

If discovered, attackers will attempt to harvest information from the WebDAV
enabled directories, or even upload malicious files that could then be used to
compromise the server.

Arachni discovered that the affected page allows WebDAV access. This was discovered
as the server allowed several specific methods that are specific to WebDAV (`PROPFIND`,
`PROPPATCH`, etc.), however, further testing should be conducted on the WebDAV
component specifically as Arachni does support this feature.
},
                references:  {
                    'WebDAV.org' => 'http://www.webdav.org/specs/rfc4918.html',
                    'Wikipedia'  => 'http://en.wikipedia.org/wiki/WebDAV',
                },
                tags:            %w(webdav options methods server),
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{
Identification of the requirement to run a WebDAV server should be considered.
If it is not required then it should be disabled. However, if it is required to
meet the application functionality, then it should be protected by SSL/TLS as
well as the implementation of a strong authentication mechanism.
}
            }

        }
    end

end
