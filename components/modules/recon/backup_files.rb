=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Backup file discovery module.
#
# Appends common backup extentions to the filename of the page under audit<br/>
# and checks for its existence.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.2
#
#
class Arachni::Modules::BackupFiles < Arachni::Module::Base

    def self.extensions
        @extensions ||= read_file( 'extensions.txt' )
    end

    def run
        path = get_path( page.url )
        return if audited?( path )

        filename = File.basename( uri_parse( page.url ).path )

        if !filename || filename.empty? || filename == '/'
            print_info "Backing out, couldn't extract filename from: #{page.url}"
            return
        end

        self.class.extensions.each do |ext|
            file = ext % filename # Example: index.php.bak
            log_remote_file_if_exists( path + file )

            cfile = ext % filename.gsub( /\.(.*)/, '' ) # Example: index.bak
            log_remote_file_if_exists( path + cfile ) if file != cfile
        end

        audited( path )
    end

    def self.info
        {
            name:        'Backup files',
            description: %q{Tries to find sensitive backup files.},
            elements:    [ Element::PATH ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2.2',
            targets:     %w(Generic),
            references: {
                'WebAppSec' => 'http://www.webappsec.org/projects/threat/classes/information_leakage.shtml'
            },
            issue:       {
                name:            %q{Backup file},
                description:     %q{The server response indicates that a file matching
    the name of a common naming scheme for file backups can be publicly accessible.
    A developer has probably forgotten to remove this file after testing.
    This can lead to source code disclosure and privileged information leaks.},
                tags:            %w(path backup file discovery),
                cew:             '530',
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{Do not keep alternative versions of files underneath the virtual web server root.
                    When updating the site, delete or move the files to a directory outside the virtual root, edit them there,
                    and move (or copy) the files back to the virtual root. Make sure that only the files that are actually in use reside under the virtual root.}
            }

        }
    end

end
