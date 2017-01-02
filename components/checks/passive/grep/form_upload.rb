=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Looks for and logs forms with file inputs.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::FormUpload < Arachni::Check::Base

    def run
        page.forms.each do |form|
            form.inputs.keys.each do |name|
                next if form.details_for( name )[:type] != :file

                log(
                    proof: form.node.nodes_by_attribute_name_and_value( 'type','file' ).first.to_html,
                    vector: form
                )
            end
        end
    end

    def self.info
        {
            name:        'Form-based File Upload',
            description: 'Logs upload forms which require manual testing.',
            elements:    [ Element::Form ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.2.3',

            issue:       {
                name:        %q{Form-based File Upload},
                description: %q{
The design of many web applications require that users be able to upload files
that will either be stored or processed by the receiving web server.

Arachni has flagged this not as a vulnerability, but as a prompt for the
penetration tester to conduct further manual testing on the file upload function.

An insecure form-based file upload could allow a cyber-criminal a means to abuse
and successfully exploit the server directly, and/or any third party that may
later access the file. This can occur through uploading a file containing server
side-code (such as PHP) that is then executed when requested by the client.
},
                references:  {
                    'owasp.org' => 'https://www.owasp.org/index.php/Unrestricted_File_Upload'
                },
                cwe:         200,
                tags:        %w(file upload),
                severity:    Severity::INFORMATIONAL,
                remedy_guidance: %q{
The identified page should at a minimum:

1. Whitelist permitted file types and block all others. This should be conducted
    on the MIME type of the file rather than its extension.
2. As the file is uploaded, and prior to being handled (written to the disk) by
    the server, the filename should be stripped of all control, special, or
    Unicode characters.
3. Ensure that the upload is conducted via the HTTP `POST` method rather than
    `GET` or `PUT`.
4. Ensure that the file is written to a directory that does not hold any execute
    permission and that all files within that directory inherit the same permissions.
5. Scan (if possible) with an up-to-date virus scanner before being stored.
6. Ensure that the application handles files as per the host operating system.
    For example, the length of the file name is appropriate, there is adequate
    space to store the file, protection against overwriting other files etc.
}
            },
            max_issues: 25
        }
    end

end
