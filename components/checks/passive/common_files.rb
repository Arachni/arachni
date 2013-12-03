=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Looks for sensitive common files on the server.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.2
#
class Arachni::Checks::CommonFiles < Arachni::Check::Base

    def self.filenames
        @filenames ||= read_file( 'filenames.txt' )
    end

    def run
        path = get_path( page.url )
        return if audited?( path )

        self.class.filenames.each { |file| log_remote_file_if_exists( path + file ) }
        audited( path )
    end

    def self.info
        {
            name:        'Common files',
            description: %q{Tries to find common sensitive files on the server.},
            elements:    [ Element::Path ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2.2',
            targets:     %w(Generic),
            references: {
                'Apache.org' => 'http://httpd.apache.org/docs/2.0/mod/mod_access.html'
            },
            issue:       {
                name:            %q{Common sensitive file},
                tags:            %w(common path file discovery),
                severity:        Severity::LOW,
                remedy_guidance: %q{Do not expose file and directory information to the user.}
            }
        }
    end

end
