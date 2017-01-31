=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Common directories discovery check.
#
# Looks for common, possibly sensitive, directories on the server.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @see http://cwe.mitre.org/data/definitions/538.html
class Arachni::Checks::CommonDirectories < Arachni::Check::Base

    def self.directories
        @directories ||= read_file( 'directories.txt' )
    end

    def run
        return if page.code != 200

        path = get_path( page.url )
        return if audited?( path )

        self.class.directories.each do |dirname|
            log_remote_directory_if_exists( path + dirname + '/' )
        end

        audited( path )
    end

    def self.info
        {
            name:        'Common directories',
            description: %q{Tries to find common directories on the server.},
            elements:    [ Element::Server ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:     '0.2.3',

            issue:       {
                name:            %q{Common directory},
                description:     %q{
Web applications are often made up of multiple files and directories.

It is possible that over time some directories may become unreferenced (unused)
by the web application and forgotten about by the administrator/developer.
Because web applications are built using common frameworks, they contain common
directories that can be discovered (independent of server).

During the initial recon stages of an attack, cyber-criminals will attempt to
locate unreferenced directories in the hope that the directory will assist in further
compromise of the web application.
To achieve this they will make thousands of requests using word lists containing
common names.
The response headers from the server will then indicate if the directory exists.

Arachni also contains a list of common directory names which it will attempt to access.
},
                references: {
                    'CWE'   => 'http://cwe.mitre.org/data/definitions/538.html',
                    'OWASP' => 'https://www.owasp.org/index.php/Forced_browsing'
                },
                tags:            %w(path directory common discovery),
                cwe:             538,
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{
If directories are unreferenced then they should be removed from the web root
and/or the application directory.

Preventing access without authentication may also be an option and can stop a
client from being able to view the contents of a file, however it is still likely
that the directory structure will be able to be discovered.

Using obscure directory names is implementing security through obscurity and is
not a recommended option.
}
            }
        }
    end

end
