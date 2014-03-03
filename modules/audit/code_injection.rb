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

# It's designed to work with PHP, Perl, Python, Java, ASP and Ruby
# but still needs some more testing.
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.1
#
# @see http://cwe.mitre.org/data/definitions/94.html
# @see http://php.net/manual/en/function.eval.php
# @see http://perldoc.perl.org/functions/eval.html
# @see http://docs.python.org/py3k/library/functions.html#eval
# @see http://www.aspdev.org/asp/asp-eval-execute/
# @see http://en.wikipedia.org/wiki/Eval#Ruby
class Arachni::Modules::CodeInjection < Arachni::Module::Base

    def self.rand1
        @rand1 ||= '287630581954'
    end

    def self.rand2
        @rand2 ||= '4196403186331128'
    end

    def self.options
        @options ||= {
            substring: (rand1.to_i + rand2.to_i).to_s,
            format:    [Format::APPEND, Format::STRAIGHT],
            param_flip: false
        }
    end

    def self.code_strings
        # code strings to be injected to the webapp
        @code_strings ||= {
            php:    "echo #{rand1}+#{rand2};",
            perl:   "print #{rand1}+#{rand2};",
            python: "print #{rand1}+#{rand2}",
            asp:    "Response.Write\x28#{rand1}+#{rand2}\x29"
        }
    end

    def self.payloads
        return @payloads if @payloads

        @payloads = {}
        code_strings.each do |platform, payload|
            @payloads[platform] = [ ';%s', "\";%s#", "';%s#" ].
                map { |var| var % payload } | [payload]
        end
        @payloads
    end

    def run
        audit( self.class.payloads, self.class.options )
    end

    def self.info
        {
            name:        'Code injection',
            description: %q{It tries to inject code snippets into the
                web application and assess whether or not the injection
                was successful.},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2.1',
            references:  {
                'PHP'    => 'http://php.net/manual/en/function.eval.php',
                'Perl'   => 'http://perldoc.perl.org/functions/eval.html',
                'Python' => 'http://docs.python.org/py3k/library/functions.html#eval',
                'ASP'    => 'http://www.aspdev.org/asp/asp-eval-execute/',
            },
            targets:     %w(PHP Perl Python ASP),
            issue:       {
                name:            %q{Code injection},
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
                    Arachni was able to inject specific server side code and 
                    have the executed output from the code contained within the 
                    server response. This indicates that proper input 
                    sanitisation is not occurring.},
                tags:            %w(code injection regexp),
                cwe:             '94',
                severity:        Severity::HIGH,
                cvssv2:          '7.5',
                remedy_guidance: %q{ It is recommended that untrusted or 
                    invalidated data is never stored where it may then be 
                    executed as server side code. To validate data, the 
                    application should ensure that the supplied value contains 
                    only the characters that are required to perform the 
                    required action. For example, where a username is required, 
                    then no non-alpha characters should be accepted. 
                    Additionally, within PHP, the "eval" and "preg_replace" 
                    functions should be avoided as these functions can easily be 
                    used to execute untrusted data. If these functions are used 
                    within the application then these parts should be rewritten. 
                    The exact way to rewrite the code depends on what the code 
                    in question does, so there is no general pattern for doing 
                    so. Once the code has been rewritten the eval() function 
                    should be disabled. This can be achieved by adding eval to 
                    disable_funcions within the php.ini file.},
                remedy_code:     '',
                metasploitable:  'unix/webapp/arachni_php_eval'
            }

        }
    end

end
