=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Backup file discovery check.
#
# Appends common backup extentions to the filename of the page under audit<br/>
# and checks for its existence.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.3
class Arachni::Checks::BackupFiles < Arachni::Check::Base

    def self.formats
        @formats ||= read_file( 'formats.txt' )
    end

    def run
        resource = page.parsed_url.without_query
        return if audited?( resource )

        if page.parsed_url.path.to_s.empty? || page.parsed_url.path.end_with?( '/' )
            print_info "Backing out, couldn't extract filename from: #{page.url}"
            return
        end

        path      = page.parsed_url.up_to_path
        name      = File.basename( page.parsed_url.path ).split( '.' ).first.to_s
        extension = page.parsed_url.resource_extension.to_s

        self.class.formats.each do |format|
            log_remote_file_if_exists( path + format.gsub( '[name]', name ).gsub( '[extension]', extension ) )
        end

        audited( resource )
    end

    def self.info
        {
            name:        'Backup files',
            description: %q{Tries to find sensitive backup files.},
            elements:    [ Element::Server ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.3',

            issue:       {
                name:            %q{Backup file},
                description:     %q{The server response indicates that a file matching
    the name of a common naming scheme for file backups can be publicly accessible.
    A developer has probably forgotten to remove this file after testing.
    This can lead to source code disclosure and privileged information leaks.},
                references: {
                    'WebAppSec' => 'http://www.webappsec.org/projects/threat/classes/information_leakage.shtml'
                },
                tags:            %w(path backup file discovery),
                cwe:             530,
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{Do not keep alternative versions of files underneath the virtual web server root.
                    When updating the site, delete or move the files to a directory outside the virtual root, edit them there,
                    and move (or copy) the files back to the virtual root. Make sure that only the files that are actually in use reside under the virtual root.}
            }

        }
    end

end
