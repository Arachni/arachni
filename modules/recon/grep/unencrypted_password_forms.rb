=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Unencrypted password form
#
# Looks for password inputs that don't submit data over an encrypted channel (HTTPS).
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.6
#
# @see http://www.owasp.org/index.php/Top_10_2010-A9-Insufficient_Transport_Layer_Protection
#
class Arachni::Modules::UnencryptedPasswordForms < Arachni::Module::Base

    def determine_name( input )
        input['name'] || input['id']
    end

    def password?( input )
        input['type'].to_s.downcase == 'password'
    end

    def check_form?( form )
        uri_parse( form.action ).scheme.downcase == 'http' && form.raw['auditable']
    end

    def run
        page.forms.each { |form| check_and_log( form ) }
    end

    def check_and_log( form )
        return if !check_form?( form )

        form.raw['auditable'].each do |input|
            name = determine_name( input )
            next if !password?( input ) || audited?( input ) || !name

            log( var: name, match: form.to_html, element: Element::FORM )

            print_ok( "Found unprotected password field '#{name}' at #{page.url}" )
            audited( input )
        end
    end

    def self.info
        {
            name:        'Unencrypted password forms',
            description: %q{Looks for password inputs that don't submit data
                over an encrypted channel (HTTPS).},
            elements:    [ Element::FORM ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.6',
            references:  {
                'OWASP Top 10 2010' => 'http://www.owasp.org/index.php/Top_10_2010-A9-Insufficient_Transport_Layer_Protection'
            },
            targets:     %w(Generic),
            issue:       {
                name:            %q{Unencrypted password form},
                description:     %q{Transmission of password does not use an encrypted channel.},
                tags:            %w(unencrypted password form),
                cwe:             '319',
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{Forms with sensitive content, like passwords, must be sent over HTTPS.}
            }

        }
    end

end
