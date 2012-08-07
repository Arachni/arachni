=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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
# Tries to inject code strings which, if executed, would cause an identifiable
# delay in execution.
#
# If that delay can be verified then the vector via which it was introduced is
# flagged as vulnerable.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.2
#
# @see http://cwe.mitre.org/data/definitions/94.html
# @see http://php.net/manual/en/function.eval.php
# @see http://perldoc.perl.org/functions/eval.html
# @see http://docs.python.org/py3k/library/functions.html#eval
# @see http://www.aspdev.org/asp/asp-eval-execute/
# @see http://en.wikipedia.org/wiki/Eval#Ruby
#
class Arachni::Modules::CodeInjectionTiming < Arachni::Module::Base

    def self.code_strings
        @code_strings ||= []

        if @code_strings.empty?
            read_file( 'payloads.txt' ) do |str|
                [ ' ', ' && ', ';' ].each { |sep| @code_strings << "#{sep} #{str}"}
            end
        end

        @code_strings
    end

    def run
        audit_timeout( self.class.code_strings, format: [Format::STRAIGHT], timeout: 4000 )
    end

    # If the simple code injection module has already logged an element
    # don't waste time re-auditing it.
    def self.preferred
        %w(code_injection)
    end

    def self.info
        {
            name:        'Code injection (timing)',
            description: %q{It tries to inject code snippets into the
                web application and assess whether or not the injection
                was successful using a time delay.},
            elements:    [ Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.2.2',
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
                description:     %q{Arbitrary code can be injected into the web application
    which is then executed as part of the system.
    (This issue was discovered using a timing attack; timing attacks
    can result in false positives in cases where the server takes
    an abnormally long time to respond.
    Either case, these issues will require further investigation
    even if they are false positives.)},
                tags:            %w(code injection timing blind),
                cwe:             '94',
                severity:        Severity::HIGH,
                cvssv2:          '7.5',
                remedy_guidance: %q{User inputs must be validated and filtered
    before being evaluated as executable code.
    Better yet, the web application should stop evaluating user
    inputs as any part of dynamic code altogether.},
                remedy_code:     '',
                metasploitable:  'unix/webapp/arachni_php_eval'
            }

        }
    end

end
