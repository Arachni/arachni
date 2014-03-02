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

# Looks for and logs forms with file inputs.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2
class Arachni::Modules::FileUpload < Arachni::Module::Base


    def run
        page.forms.each do |form|
            next if form.raw.empty?

            form.raw['input'].each do |input|
                next if input['type'] != 'file'
                log( match: form.to_html, element: Element::FORM )
            end
        end
    end

    def self.info
        {
            name:        'Form-based File Upload',
            description: %q{Logs file upload forms which require manual testing.},
            elements:    [ Element::FORM ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2',
            targets:     %w(Generic),
            references: {
                'owasp.org' => 'https://www.owasp.org/index.php/Unrestricted_File_Upload'
            },

            issue:       {
                name:        %q{Form-based File Upload},
                cwe:         '200',
                description: %q{The design of many web applications require that 
                    users be able to upload files that will either be stored or 
                    processed by the receiving web server. Arachni has flagged 
                    this not as a vulnerability, but as a prompt for the 
                    penetration tester to conduct further manual testing on the 
                    file upload function. An insecure form based file upload 
                    could allow a cyber-criminal a means to abuse and 
                    successfully exploit the server directly, and/or any third 
                    party that may later access the file. This can occur through 
                    uploading a file containing server side code (such as PHP) 
                    that is then executed when requested by the client. For more 
                    information on possible methods of compromise refer to 
                    'www.owasp.org/index.php/Unrestricted_File_Upload'},
                tags:        %w(file upload),
                severity:    Severity::INFORMATIONAL,
                remedy_guidance: %q{The identified page should at a minimum: 1. 
                    Whitelist permitted file types and block all others. This 
                    should be conducted on the MIME type of the file rather than 
                    its extension. 2. As the file is uploaded, and prior to 
                    being handled (written to the disk) by the server, the 
                    filename should be stripped of all control, special, or 
                    Unicode characters. 3. Ensure that the upload is conducted 
                    via the HTTP POST method rather than GET or PUT. 4. Ensure 
                    that the file is written to a directory that does not hold 
                    any execute permission, and that all files within that 
                    directory inherit the same permissions. 5. Scan (if 
                    possible) with an up-to-date virus scanner before being 
                    stored. 6. Ensure that the applications handles files as per 
                    the host operating system. For example the length of the 
                    file name is appropriate, there is adequate space to store 
                    the file, protection against overwriting other files etc.},
            },
            max_issues: 25
        }
    end


end
