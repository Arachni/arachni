=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Backup file discovery check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::BackupFiles < Arachni::Check::Base

    def self.formats
        @formats ||= read_file( 'formats.txt' )
    end

    def run
        return if page.code != 200

        resource = page.parsed_url.without_query
        return if audited?( resource )

        if page.parsed_url.path.to_s.empty? || page.parsed_url.path.end_with?( '/' )
            print_info "Backing out, couldn't extract filename from: #{page.url}"
            return
        end

        up_to_path = page.parsed_url.up_to_path
        name       = File.basename( page.parsed_url.path ).split( '.' ).first.to_s
        extension  = page.parsed_url.resource_extension.to_s

        self.class.formats.each do |format|
            url = up_to_path + format.gsub( '[name]', name ).
                gsub( '[extension]', extension )

            # If there's no extension we'll end up with '..' in URLs.
            url.gsub!('..', '.')

            next if audited?( url )

            log_remote_file_if_exists( url )
            audited( url )
        end

        audited( resource )
    end

    def self.info
        {
            name:             'Backup files',
            description:      %q{Tries to identify backup files.},
            elements:         [ Element::Server ],
            author:           'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:          '0.3.2',
            exempt_platforms: Arachni::Platform::Manager::FRAMEWORKS,

            issue:       {
                name:            %q{Backup file},
                description:     %q{
A common practice when administering web applications is to create a copy/backup
of a particular file or directory prior to making any modification to the file.
Another common practice is to add an extension or change the name of the original
file to signify that it is a backup (examples include `.bak`, `.orig`, `.backup`,
etc.).

During the initial recon stages of an attack, cyber-criminals will attempt to
locate backup files by adding common extensions onto files already discovered on
the webserver. By analysing the response headers from the server they are able to
determine if the backup file exists.
These backup files can then assist in the compromise of the web application.

By utilising the same method, Arachni was able to discover a possible backup file.
},
                references: {
                    'WebAppSec' => 'http://www.webappsec.org/projects/threat/classes/information_leakage.shtml'
                },
                tags:            %w(path backup file discovery),
                cwe:             530,
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{
Do not keep obsolete versions of files under the virtual web server root.

When updating the site, delete or move the files to a directory outside the
virtual root, edit them there, and move (or copy) the files back to the virtual
root.
Make sure that only the files that are actually in use reside under the virtual root.

Preventing access without authentication may also be an option and stop a client
being able to view the contents of a file, however it is still likely that the
filenames will be able to be discovered.

Using obscure filenames is only implementing security through obscurity and is
not a recommended option.
}
            }

        }
    end

end
