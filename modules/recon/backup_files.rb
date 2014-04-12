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

# Backup file discovery module.
#
# Appends common backup extentions to the filename of the page under audit<br/>
# and checks for its existence.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.2.3
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
            version:     '0.2.3',
            targets:     %w(Generic),
            references: {
                'WASC 1' => 'http://www.webappsec.org/projects/threat/classes/information_leakage.shtml',
                'WASC 2' => 'http://projects.webappsec.org/w/page/13246953/Predictable%20Resource%20Location'
            },
            issue:       {
                name:            %q{Backup file},
                description:     %q{A common practice when administering web 
                    applications is to create a copy/backup of a particular file 
                    or directory prior to making any modification to the file. 
                    Another common practice is to add an extension or change the
                    name of the original file to signify that it is a backup
                    (examples include .bak, .orig, .backup, etc.). During the 
                    initial recon stages of an attack, cyber-criminals will
                    attempt to locate backup files by adding common extensions 
                    onto files already discovered on the webserver. By analysing 
                    the response headers from the server they are able to 
                    determine if the backup file exists. These backup files can 
                    then assist in further compromise of the web application. By 
                    utilising the same method, Arachni was able to discover a 
                    possible backup file.},
                tags:            %w(path backup file discovery),
                cew:             '530',
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{Do not keep obsolete versions of files
                    under the virtual web server root. When updating the
                    site, delete or move the files to a directory outside the 
                    virtual root, edit them there, and move (or copy) the files 
                    back to the virtual root. Make sure that only the files that 
                    are actually in use reside under the virtual root. 
                    Preventing access without authentication may also be an 
                    option and stop a client being able to view the contents of 
                    a file, however it is still likely that the filenames will be
                    able to be discovered. Using obscure filenames is only 
                    implementing security through obscurity and is not a 
                    recommended option.}
            }

        }
    end

end
