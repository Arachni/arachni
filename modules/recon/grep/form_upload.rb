=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
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
