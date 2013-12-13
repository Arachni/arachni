=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Common directories discovery check.
#
# Looks for common, possibly sensitive, directories on the server.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.2.2
#
# @see http://cwe.mitre.org/data/definitions/538.html
class Arachni::Checks::CommonDirectories < Arachni::Check::Base

    def self.directories
        @directories ||= read_file( 'directories.txt' )
    end

    def run
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
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2.1',
            targets:     %w(Generic),

            issue:       {
                name:            %q{Common directory},
                references: {
                    'CWE'   => 'http://cwe.mitre.org/data/definitions/538.html',
                    'OWASP' => 'https://www.owasp.org/index.php/Forced_browsing'
                },
                tags:            %w(path directory common discovery),
                cwe:             538,
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{Do not expose file and directory information to the user.}
            }

        }
    end

end
