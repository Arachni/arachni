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
# @version 0.1
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
        description = 'Logs upload forms which require manual testing.'
        {
            name:        'Form-based File Upload',
            description: description,
            elements:    [ Element::FORM ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            targets:     %w(Generic),
            references: {
                'owasp.org' => 'https://www.owasp.org/index.php/Unrestricted_File_Upload'
            },

            issue:       {
                name:        %q{Form-based File Upload},
                cwe:         '200',
                description: description,
                tags:        %w(file upload),
                severity:    Severity::INFORMATIONAL
            },
            max_issues: 25
        }
    end


end
