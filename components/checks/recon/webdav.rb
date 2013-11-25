=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
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
#
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

        http.request( path, method: :options ) { |res| check_and_log( res ) }
        audited( path )
    end

    def self.info
        {
            name:        'WebDAV',
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
                name:            %q{WebDAV},
                description:     %q{WebDAV is enabled on the server.
    Consider auditing further using a specialised tool.},
                tags:            %w(webdav options methods server),
                severity:        Severity::INFORMATIONAL,
                remedy_guidance: %q{Disable WebDAV if not required. If it is required, perform an audit using specialized tools.}
            }

        }
    end

    def check_and_log( res )
        begin
            allowed = res.headers['Allow'].split( ',' ).map { |method| method.strip }
            return if !allowed.include?( self.class.dav_method )
        rescue
            return
        end

        self.class.found

        log( { element: Element::SERVER }, res )
        print_ok "Enabled for: #{res.url}"
    end

end
