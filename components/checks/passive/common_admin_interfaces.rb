=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Looks for common administration interfaces on the server.
#
# @author Brendan Coles <bcoles@gmail.com>
# @author Tasos Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::CommonAdminInterfaces < Arachni::Check::Base

    def self.resources
        @filenames ||= read_file( 'admin-panels.txt' )
    end

    def run
        return if page.code != 200

        path = get_path( page.url )
        return if audited?( path )

        self.class.resources.each do |file|
            log_remote_file_if_exists( path + file )
        end

        audited( path )
    end

    def self.info
        {
            name:        'Common administration interfaces',
            description: %q{Tries to find common admin interfaces on the server.},
            elements:    [ Element::Server ],
            author:      [
                'Brendan Coles <bcoles@gmail.com>',
                'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>'
            ],
            version:     '0.1.1',
            targets:     %w(Generic),
            references: {
                'Apache.org' => 'http://httpd.apache.org/docs/2.0/mod/mod_access.html',
                'WASC'       => 'http://projects.webappsec.org/w/page/13246953/Predictable%20Resource%20Location'
            },
            issue: {
                name:            %q{Common administration interface},
                description:     %q{An administration interface was identified and should be reviewed.},
                tags:            %w(common path file discovery),
                severity:        Severity::LOW,
                remedy_guidance: %q{
Access to administration interfaces should be restricted to trusted IP addresses only.
}
            }
        }
    end

end
