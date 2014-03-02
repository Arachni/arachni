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
# @version 0.2.3
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
            version:     '0.2.3',
            targets:     %w(Generic),
            references: {
                'CWE'   => 'http://cwe.mitre.org/data/definitions/538.html',
                'OWASP' => 'https://www.owasp.org/index.php/Forced_browsing',
                'WASC' => 'http://projects.webappsec.org/w/page/13246953/Predictable%20Resource%20Location'
            },
            issue:       {
                name:            %q{Common directory},
                description:     %q{Web applications are often made up of 
                    multiple files and directories. It is possible that over 
                    time some directories may become unreferenced (used) by the 
                    web application and forgotten about by the 
                    administrator/developer. Because web applications are built 
                    using common frameworks, they contain common directories 
                    that can be discovered (independent of server). During the 
                    initial recon stages of an attack cyber-criminals will 
                    attempt to locate unreferenced directories in the hope that 
                    the file will assist in further compromise of the web 
                    application. To achieve this they will make thousands of 
                    requests using word lists containing common filenames. The 
                    response headers from the server will then indicate if the 
                    file exists. Arachni also contains a list of common file 
                    names which it will attempt to access. Based off the server 
                    response the affected file was discovered.},
                tags:            %w(path directory common discovery),
                cwe:             '538',
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{If directories are unreferenced then they 
                    should be removed from the web root, and/or the application 
                    directory. Preventing access without authentication may also 
                    be an option and stop a client being able to view the 
                    contents of a file however it is still likely that the 
                    directory structure will be able to be discovered. Using 
                    obscure directory names is only implementing security 
                    through obscurity and is not a recommended option.}
            }

        }
    end

end
