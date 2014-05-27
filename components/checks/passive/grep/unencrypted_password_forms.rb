=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Unencrypted password form
#
# Looks for password inputs that don't submit data over an encrypted channel (HTTPS).
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.2
#
# @see http://www.owasp.org/index.php/Top_10_2010-A9-Insufficient_Transport_Layer_Protection
class Arachni::Checks::UnencryptedPasswordForms < Arachni::Check::Base

    def run
        page.forms.each { |form| check_and_log( form ) }
    end

    def check_and_log( form )
        return if !check_form?( form )

        form.inputs.each do |name, v|
            next if form.field_type_for( name ) != :password || audited?( form.id )

            cform = form.dup
            cform.affected_input_name = name
            log( vector: cform, proof: form.html )

            print_ok( "Found unprotected password field '#{name}' at #{page.url}" )
            audited form.id
        end
    end

    def check_form?( form )
        uri_parse( form.action ).scheme.downcase == 'http'
    end

    def self.info
        {
            name:        'Unencrypted password forms',
            description: %q{Looks for password inputs that don't submit data
                over an encrypted channel (HTTPS).},
            elements:    [ Element::Form ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2',

            issue:       {
                name:            %q{Unencrypted password form},
                description:     %q{Transmission of password does not use an encrypted channel.},
                references:  {
                    'OWASP Top 10 2010' => 'http://www.owasp.org/index.php/Top_10_2010-A9-Insufficient_Transport_Layer_Protection'
                },
                tags:            %w(unencrypted password form),
                cwe:             319,
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{Forms with sensitive content, like passwords, must be sent over HTTPS.}
            }

        }
    end

end
