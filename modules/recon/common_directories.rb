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
# Common directories discovery module.
#
# Looks for common, possibly sensitive, directories on the server.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.2
#
# @see http://cwe.mitre.org/data/definitions/538.html
#
class Arachni::Modules::CommonDirectories < Arachni::Module::Base

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
            elements:    [ Element::PATH ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2.1',
            targets:     %w(Generic),
            references: {
                'CWE'   => 'http://cwe.mitre.org/data/definitions/538.html',
                'OWASP' => 'https://www.owasp.org/index.php/Forced_browsing'
            },
            issue:       {
                name:            %q{Common directory},
                tags:            %w(path directory common discovery),
                cwe:             '538',
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{Do not expose file and directory information to the user.}
            }

        }
    end

end
