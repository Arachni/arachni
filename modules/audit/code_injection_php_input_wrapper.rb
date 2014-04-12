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

# @see OWASP    https://www.owasp.org/index.php/Top_10_2007-Malicious_File_Execution
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2
class Arachni::Modules::CodeExecutionPHPInputWrapper < Arachni::Module::Base

    def self.options
        @options ||= {
            format:    [Format::STRAIGHT],
            body:      "<?php echo 'vDBVBsbVdv'; ?> <?php echo chr(80).chr(76).chr(76).chr(33).chr(56).chr(111).chr(55) ?>",
            substring: 'vDBVBsbVdv PLL!8o7',

            # Add one more mutation (on the fly) which will include the extension
            # of the original value (if that value was a filename) after a null byte.
            each_mutation: proc do |mutation|
                m = mutation.dup

                # Figure out the extension of the default value, if it has one.
                ext = m.original[m.altered].to_s.split( '.' )
                ext = ext.size > 1 ? ext.last : nil

                # Null-terminate the injected value and append the ext.
                m.altered_value += "\x00.#{ext}"

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
            description: %q{It injects PHP code into the HTTP request body and
                uses the php://input wrapper to try and load it.},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2',
            references:  {
                'OWASP'     => 'https://www.owasp.org/index.php/Top_10_2007-Malicious_File_Execution'
            },
            targets:     %w(PHP),
            issue:       {
                name:            %q{Code injection (php://input wrapper)},
                description:     %q{A modern web application will be reliant on 
                    several different programming languages. These languages can 
                    be broken up into two flavours. These are client side 
                    languages such as those that run in the browser eg. 
                    JavaScript and HTML, and server side languages that are 
                    executed by the server (ASP, PHP, JSP, etc) to form the 
                    dynamic pages (client side code) that are then sent to the 
                    client. Because all server side code should be executed by 
                    the server, it should only ever come from a trusted source. 
                    Code injection occurs when the server takes untrusted server 
                    side code (ie. From the client) and executes the code as if 
                    it were on the server. Cyber-criminals will abuse this 
                    weakness to execute their own arbitrary code on the server, 
                    and could result in complete compromise of the server. 
                    Arachni was able to inject specific server side code wrapped 
                    within a php wrapper (<?php ... ?>) and have the executed 
                    output from the code contained within the server response. 
                    This indicates that proper input sanitisation is not 
                    occurring..},
                tags:            %w(remote injection php code execution),
                cwe:             '94',
                severity:        Severity::HIGH,
                remedy_guidance: %q{It is recommended that untrusted or 
                    invalidated data is never stored where it may then be 
                    executed as server side code. To validate data, the 
                    application should ensure that the supplied value contains 
                    nly the characters that are required to perform the required 
                    action. For example, where a username is required, then no 
                    non-alpha characters should be accepted. Additionally, 
                    within PHP, the "eval" and "preg_replace" functions should 
                    be avoided as these functions can easily be used to execute 
                    untrusted data. If these functions are used within the 
                    application then these parts should be rewritten. The exact 
                    way to rewrite the code depends on what the code in question 
                    does, so there is no general pattern for doing so. Once the 
                    code has been rewritten the eval() function should be 
                    disabled. This can be achieved by adding eval to 
                    disable_funcions within the php.ini file.},
            }

        }
    end

end
