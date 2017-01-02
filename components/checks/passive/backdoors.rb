=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Looks for common backdoors on the server.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::Backdoors < Arachni::Check::Base

    def self.filenames
        @filenames ||= read_file( 'filenames.txt' )
    end

    def run
        return if page.code != 200

        path = get_path( page.url )
        return if audited?( path )

        self.class.filenames.each { |file| log_remote_file_if_exists( path + file ) }
        audited( path )
    end

    def self.info
        {
            name:             'Backdoors',
            description:      %q{Tries to find common backdoors on the server.},
            elements:         [Element::Server],
            author:           'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:          '0.2.6',
            exempt_platforms: Arachni::Platform::Manager::FRAMEWORKS,

            issue:       {
                name:            %q{A backdoor file exists on the server},
                description:     %q{
If a server has been previously compromised, there is a high probability that the
cyber-criminal has installed a backdoor so that they can easily return to the
server if required.
One method of achieving this is to place a web backdoor or web shell within the
web root of the web server. This will then enable the cyber-criminal to access
the server through a HTTP/S session.

Although extremely bad practice, it is possible that the web backdoor or web shell
has been placed there by an administrator so they can perform administrative
activities remotely.

During the initial recon stages of an attack, cyber-criminals will attempt to
locate these web backdoors or shells by requesting the names of the most common
and well known ones.

By analysing the response, they are able to determine if a web backdoor or web
shell exists. These web backdoors or web shells can then provide an easy path
for further compromise of the server.

By utilising the same methods as the cyber-criminals, Arachni was able to
discover a possible web backdoor or web shell.
},
                references:  {
                    'Blackhat' => 'https://www.blackhat.com/presentations/bh-usa-07/Wysopal_and_Eng/Presentation/bh-usa-07-wysopal_and_eng.pdf'
                },
                tags:            %w(path backdoor file discovery),
                severity:        Severity::HIGH,
                remedy_guidance: %q{
If manual confirmation reveals that a web backdoor or web shell does exist on
the server, then it should be removed.
It is also recommended that an incident response investigation be conducted on
the server to establish how the web backdoor or web shell came to end up on the
server.

Depending on the environment, investigation into the compromise of any other
services or servers should be conducted.
}

            }
        }
    end

end
