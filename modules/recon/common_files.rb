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

# Looks for sensitive common files on the server.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.2.3
class Arachni::Modules::CommonFiles < Arachni::Module::Base

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
            elements:    [ Element::PATH ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2.3',
            targets:     %w(Generic),
            references: {
                'Apache.org' => 'http://httpd.apache.org/docs/2.0/mod/mod_access.html',
                'WASC' => 'http://projects.webappsec.org/w/page/13246953/Predictable%20Resource%20Location'
            },
            issue:       {
                name:            %q{Common sensitive file},
                description:     %q{Web applications are often made up of 
                    multiple files and directories, however it is possible that 
                    over time some files may become unreferenced (unused) by the
                    web application and forgotten by the administrator/developer.
                    Because web applications are built
                    using common frameworks, they contain common files that can 
                    be discovered (independent of server). During the initial recon
                    stages of an attack cyber-criminals will attempt to locate 
                    unreferenced files in the hope that the file will assist in 
                    further compromise of the web application. To achieve this 
                    they will make thousands of requests using word lists 
                    containing common filenames. The response headers from the 
                    server will then indicate if the file exists. Arachni also 
                    contains a list of common file names which it will attempt 
                    to access.},
                tags:            %w(common path file discovery),
                severity:        Severity::LOW,
                remedy_guidance: %q{If files are unreferenced then they should 
                    be removed from the web root, and/or the application 
                    directory. Preventing access without authentication may also 
                    be an option and stop a client from being able to view the
                    contents of a file, however it is still likely that the
                    filenames will be able to be discovered. Using obscure 
                    filenames is only implementing security through obscurity 
                    and is not a recommended option.}
            }
        }
    end

end
