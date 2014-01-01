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

#
# Looks for common backdoors on the server.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.2
#
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
            version:     '0.2.2',
            targets:     %w(Generic),
            references:  {
                'Blackhat' => 'https://www.blackhat.com/presentations/bh-usa-07/Wysopal_and_Eng/Presentation/bh-usa-07-wysopal_and_eng.pdf'
            },
            issue:       {
                name:            %q{A backdoor file exists on the server},
                description:     %q{ The server response indicates that a file matching
    the name of a common backdoor is publicly accessible.
    This indicates that the server has been compromised and can
    (to some extent) be remotely controled by unauthorised users.},
                tags:            %w(path backdoor file discovery),
                severity:        Severity::HIGH,
                remedy_guidance: %q{Perform a source code and deployment audit to eliminate any
                    unwanted files/resources and lines of code. Preferably perform a fresh deployment.}
            }

        }
    end

end
