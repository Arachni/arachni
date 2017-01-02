=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @see OWASP    https://www.owasp.org/index.php/Top_10_2007-Malicious_File_Execution
class Arachni::Checks::CodeInjectionPhpInputWrapper < Arachni::Check::Base

    def self.options
        @options ||= {
            format:     [Format::STRAIGHT],
            body:       "<?php echo 'vDBVBsbVdv'; ?> <?php echo chr(80).chr(76).chr(76).chr(33).chr(56).chr(111).chr(55) ?>",
            signatures: 'vDBVBsbVdv PLL!8o7',

            # Add one more mutation (on the fly) which will include the extension
            # of the original value (if that value was a filename) after a null byte.
            each_mutation: proc do |mutation|
                next if !mutation.affected_input_value

                # Don't bother if the current element type can't carry nulls.
                next if !mutation.valid_input_value_data?( "\0" )

                m = mutation.dup

                # Figure out the extension of the default value, if it has one.
                ext = m.default_inputs[m.affected_input_name].to_s.split( '.' )
                ext = ext.size > 1 ? ext.last : nil

                # Null-terminate the injected value and append the ext.
                m.affected_input_value += "\0.#{ext}"

                # Pass our new element back to be audited.
                m
            end
        }
    end

    def run
        audit 'php://input', self.class.options
    end

    def self.info
        {
            name:        'Code injection (php://input wrapper)',
            description: %q{
Injects PHP code into the HTTP request body and uses the `php://input` wrapper
to try and load it.
},
            elements:    [ Element::Form, Element::Link, Element::Cookie, Element::Header ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:     '0.1.3',
            platforms:   [:php],

            issue:       {
                name:        %q{Code injection (php://input wrapper)},
                description:     %q{
A modern web application will be reliant on several different programming languages.

These languages can be broken up in two flavours. These are client-side languages
(such as those that run in the browser -- like JavaScript) and server-side
languages (which are executed by the server -- like ASP, PHP, JSP, etc.) to form
the dynamic pages (client-side code) that are then sent to the client.

Because all server-side code should be executed by the server, it should only ever
come from a trusted source.

Code injection occurs when the server takes untrusted code (ie. from the client)
and executes it.

Cyber-criminals will abuse this weakness to execute arbitrary code on the server,
which could result in complete server compromise.

Arachni was able to inject specific server-side code via a PHP wrapper (`php://input`)
and have the executed output from the code contained within the server response.
This indicates that proper input sanitisation is not occurring.
},
                references:  {
                    'OWASP' => 'https://www.owasp.org/index.php/Top_10_2007-Malicious_File_Execution'
                },
                tags:        %w(remote injection php code execution),
                cwe:         94,
                severity:    Severity::HIGH,
                remedy_guidance: %q{
It is recommended that untrusted input is never processed as server-side code.

To validate input, the application should ensure that the supplied value contains
only the data that are required to perform the relevant action.

For example, where a username is required, then no non-alpha characters should not
be accepted.
}
            }
        }
    end

end
