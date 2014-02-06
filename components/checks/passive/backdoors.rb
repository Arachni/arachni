=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Looks for common backdoors on the server.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.2.2
class Arachni::Checks::Backdoors < Arachni::Check::Base

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
            name:        'Backdoors',
            description: %q{Tries to find common backdoors on the server.},
            elements:    [Element::Server],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2.2',

            issue:       {
                name:            %q{A backdoor file exists on the server},
                description:     %q{ The server response indicates that a file matching
    the name of a common backdoor is publicly accessible.
    This indicates that the server has been compromised and can
    (to some extent) be remotely controled by unauthorised users.},
                references:  {
                    'Blackhat' => 'https://www.blackhat.com/presentations/bh-usa-07/Wysopal_and_Eng/Presentation/bh-usa-07-wysopal_and_eng.pdf'
                },
                tags:            %w(path backdoor file discovery),
                severity:        Severity::HIGH,
                remedy_guidance: %q{Perform a source code and deployment audit to eliminate any
                    unwanted files/resources and lines of code. Preferably perform a fresh deployment.}
            }

        }
    end

end
