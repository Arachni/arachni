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

#
# Tries to inject code strings which, if executed, will cause an identifiable
# delay in execution.
#
# If that delay can be verified then the vector via which it was introduced is
# flagged as vulnerable.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.4
#
# @see http://cwe.mitre.org/data/definitions/94.html
# @see http://php.net/manual/en/function.eval.php
# @see http://perldoc.perl.org/functions/eval.html
# @see http://docs.python.org/py3k/library/functions.html#eval
# @see http://www.aspdev.org/asp/asp-eval-execute/
# @see http://en.wikipedia.org/wiki/Eval#Ruby
#
class Arachni::Modules::CodeInjectionTiming < Arachni::Module::Base

    prefer :code_injection

    def self.payloads
        @payloads ||= {
            ruby:   'sleep(__TIME__/1000);',
            php:    'sleep(__TIME__/1000);',
            perl:   'sleep(__TIME__/1000);',
            python: 'import time;time.sleep(__TIME__/1000);',
            jsp:    'Thread.sleep(__TIME__);',
            asp:    'Thread.Sleep(__TIME__);',
        }.inject({}) do |h, (platform, payload)|
            h[platform] = [ ' ', ' && ', ';' ].map { |sep| "#{sep} #{payload}" }
            h
        end
    end

    def run
        audit_timeout( self.class.payloads, format: [Format::STRAIGHT], timeout: 4000 )
    end

    def self.info
        {
            name:        'Code injection (timing)',
            description: %q{It tries to inject code snippets into the
                web application and assess whether or not the injection
                was successful using a time delay.},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.4',
            references:  {
                'PHP'    => 'http://php.net/manual/en/function.eval.php',
                'Perl'   => 'http://perldoc.perl.org/functions/eval.html',
                'Python' => 'http://docs.python.org/py3k/library/functions.html#eval',
                'ASP'    => 'http://www.aspdev.org/asp/asp-eval-execute/',
                'Ruby'   => 'http://en.wikipedia.org/wiki/Eval#Ruby'
            },
            targets:     %w(Java ASP Python PHP Perl Ruby),

            issue:       {
                name:            %q{Code injection (timing attack)},
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
                    and could result in complete compromise of the server. By 
                    injecting server side code that is known to take a specific 
                    amount of time to execute Arachni was able to detect time 
                    based code injection. This indicates that proper input 
                    sanitisation is not occurring.},
                tags:            %w(code injection timing blind),
                cwe:             '94',
                severity:        Severity::HIGH,
                cvssv2:          '7.5',
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
                remedy_code:     '',
                metasploitable:  'unix/webapp/arachni_php_eval'
            }

        }
    end

end
