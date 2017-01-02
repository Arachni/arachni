=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Unencrypted password form
#
# Looks for password inputs that don't submit data over an encrypted channel (HTTPS).
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://www.owasp.org/index.php/Top_10_2010-A9-Insufficient_Transport_Layer_Protection
class Arachni::Checks::UnencryptedPasswordForms < Arachni::Check::Base

    def run
        page.forms.each { |form| check_and_log( form ) }
    end

    def check_and_log( form )
        return if !check_form?( form )

        form.inputs.each do |name, v|
            next if form.field_type_for( name ) != :password

            cform = form.dup
            cform.affected_input_name = name
            log( vector: cform, proof: form.source )
        end

        audited form.id
    end

    def check_form?( form )
        uri_parse( form.action ).scheme == 'http' ||
            audited?( form.id ) || !form.requires_password?
    end

    def self.info
        {
            name:        'Unencrypted password forms',
            description: %q{Looks for password inputs that don't submit data
                over an encrypted channel (HTTPS).},
            elements:    [ Element::Form ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:     '0.2.2',

            issue:       {
                name:            %q{Unencrypted password form},
                description:     %q{
The HTTP protocol by itself is clear text, meaning that any data that is
transmitted via HTTP can be captured and the contents viewed.

To keep data private, and prevent it from being intercepted, HTTP is often
tunnelled through either Secure Sockets Layer (SSL), or Transport Layer Security
(TLS).
When either of these encryption standards are used it is referred to as HTTPS.

Cyber-criminals will often attempt to compromise credentials passed from the
client to the server using HTTP.
This can be conducted via various different Man-in-The-Middle (MiTM) attacks or
through network packet captures.

Arachni discovered that the affected page contains a `password` input, however,
the value of the field is not sent to the server utilising HTTPS. Therefore it
is possible that any submitted credential may become compromised.
},
                references:  {
                    'OWASP Top 10 2010' => 'http://www.owasp.org/index.php/Top_10_2010-A9-Insufficient_Transport_Layer_Protection'
                },
                tags:            %w(unencrypted password form),
                cwe:             319,
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{
The affected site should be secured utilising the latest and most secure encryption
protocols.
These include SSL version 3.0 and TLS version 1.2. While TLS 1.2 is the latest
and the most preferred protocol, not all browsers will support this encryption
method. Therefore, the more common SSL is included. Older protocols such as SSL
version 2, and weak ciphers (< 128 bit) should also be disabled.
}
            }
        }
    end

end
