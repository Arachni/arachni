=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Looks for and logs forms with file inputs.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2
class Arachni::Checks::FileUpload < Arachni::Check::Base


    def run
        page.forms.each do |form|
            form.inputs.keys.each do |name|
                next if form.details_for( name )[:type] != :file
                log( match: form.to_html, element: Element::Form )
            end
        end
    end

    def self.info
        description = 'Logs upload forms which require manual testing.'
        {
            name:        'Form-based File Upload',
            description: description,
            elements:    [ Element::Form ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2',
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
