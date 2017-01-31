=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::BackupDirectories < Arachni::Check::Base

    def self.formats
        @formats ||= read_file( 'formats.txt' )
    end

    def run
        return if page.code != 200

        if page.parsed_url.path.to_s.empty? || page.parsed_url.path == '/'
            print_info "Backing out, couldn't extract directory name from: #{page.url}"
            return
        end

        resource = page.parsed_url.without_query
        return if audited?( resource )

        path = "#{File.dirname( resource )}/"
        name = File.basename( page.parsed_url.path )

        self.class.formats.each do |format|
            backup_name = format.gsub( '[name]', name )
            url = path + backup_name

            remark = 'Identified by converting the original directory name of ' <<
                "'#{name}' to '#{backup_name}' using format '#{format}'."

            log_remote_file_if_exists(
                url,
                false,
                remarks: {
                    check: [ remark ]
                }
            )
        end

        audited( resource )
    end

    def self.info
        {
            name:             'Backup directories',
            description:      %q{Tries to find backed-up directories.},
            elements:         [ Element::Server ],
            author:           'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:          '0.1.3',
            exempt_platforms: Arachni::Platform::Manager::FRAMEWORKS,

            issue:       {
                name:            %q{Backup directory},
                description:     %q{
A common practice when administering web applications is to create a copy/backup
of a particular directory prior to making any modification.
Another common practice is to add an extension or change the name of the original
directory to signify that it is a backup (examples include `.bak`, `.orig`, `.backup`,
etc.).

During the initial recon stages of an attack, cyber-criminals will attempt to
locate backup directories by adding common extensions onto directories already
discovered on the webserver. By analysing the response headers from the server
they are able to determine if a backup directory exists.
These backup directories can then assist in the compromise of the web application.

By utilising the same method, Arachni was able to discover a possible backup directory.
},
                references: {
                    'WebAppSec' => 'http://www.webappsec.org/projects/threat/classes/information_leakage.shtml'
                },
                tags:            %w(path backup file discovery),
                cwe:             530,
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{
Do not keep obsolete versions of directories under the virtual web server root.

When updating the site, delete or move the directories to a directory outside the
virtual root, edit them there, and move (or copy) the directories back to the virtual
root.
Make sure that only the directories that are actually in use reside under the virtual root.

Preventing access without authentication may also be an option and stop a client
being able to view the contents of a directory6, however it is still likely that the
filenames will be able to be discovered.

Using obscure filenames is only implementing security through obscurity and is
not a recommended option.
}
            }
        }
    end

end
