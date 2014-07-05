=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Arachni::Checks::BackupDirectories < Arachni::Check::Base

    def self.formats
        @formats ||= read_file( 'formats.txt' )
    end

    def run
        if page.parsed_url.path.to_s.empty? || page.parsed_url.path == '/'
            print_info "Backing out, couldn't extract directory name from: #{page.url}"
            return
        end

        resource = page.parsed_url.without_query
        return if audited?( resource )

        path = "#{File.dirname( resource )}/"
        name = File.basename( page.parsed_url.path )

        self.class.formats.each do |format|
            log_remote_file_if_exists( path + format.gsub( '[name]', name ) )
        end

        audited( resource )
    end

    def self.info
        {
            name:        'Backup directories',
            description: %q{Tries to find backed-up directories.},
            elements:    [ Element::Server ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1',

            issue:       {
                name:            %q{Backup directory},
                description:     %q{The server response indicates that a resource matching
    the name of a common naming scheme for directory backups is publicly accessible.
    A developer has probably forgotten to remove this resource after testing.
    This can lead to source code disclosure and privileged information leaks.},
                references: {
                    'WebAppSec' => 'http://www.webappsec.org/projects/threat/classes/information_leakage.shtml'
                },
                tags:            %w(path backup file discovery),
                cwe:             530,
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{Do not keep alternative versions of resources underneath the virtual web server root.
                    When updating the site, delete or move the resources to a directory outside the virtual root, edit them there,
                    and move (or copy) the resources back to the virtual root. Make sure that only the resources that are actually in use reside under the virtual root.}
            }

        }
    end

end
