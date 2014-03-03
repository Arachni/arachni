=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

# Looks for common backdoors on the server.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.2.3
class Arachni::Modules::Backdoors < Arachni::Module::Base

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
            elements:    [Element::PATH],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2.3',
            targets:     %w(Generic),
            references:  {
                'Blackhat' => 'https://www.blackhat.com/presentations/bh-usa-07/Wysopal_and_Eng/Presentation/bh-usa-07-wysopal_and_eng.pdf'
            },
            issue:       {
                name:            %q{A backdoor file exists on the server},
                description:     %q{If a server has been previously compromised, 
                    there is a high probability that the cyber-criminal has
                    installed a backdoor so that they can easily return to the
                    server if required. One method of achieving this is to place 
                    a web backdoor or web shell within the web root of the web 
                    server. This will then enable the cyber-criminal to access 
                    the server through a HTTP/S session. Although extremely bad 
                    practice, it is possible that the web backdoor or web shell 
                    has been placed there by an administrator so they can 
                    perform administration activities remotely. During the 
                    initial recon stages of an attack cyber-criminals will 
                    attempt to locate these web backdoors or shells by
                    requesting the names of the most common and well known 
                    backdoors. By analysing the response headers from the server 
                    they are able to determine if a web backdoor or web shell 
                    exists. These web backdoors or web shells can then provide 
                    an easy path for further compromise of the server. By 
                    utilising the same methods as the cyber-criminals, Arachni 
                    was able to discover a possible web backdoor or web shell.},
                tags:            %w(path backdoor file discovery),
                severity:        Severity::HIGH,
                remedy_guidance: %q{If manual confirmation reveals that a web 
                    backdoor or web shell does exist on the server then it 
                    should be removed. It is also recommended that an incident 
                    response investigation be conducted on the server to 
                    establish how the web backdoor or web shell came to end up 
                    on the server. Depending on the environment, investigation 
                    into the compromise of any other services or servers should 
                    be conducted.}
            }

        }
    end

end
