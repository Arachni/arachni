=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Tries to inject code strings which, if executed, will cause an identifiable
# delay in execution.
#
# If that delay can be verified then the vector via which it was introduced is
# flagged as vulnerable.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.3.2
#
# @see http://cwe.mitre.org/data/definitions/94.html
# @see http://php.net/manual/en/function.eval.php
# @see http://perldoc.perl.org/functions/eval.html
# @see http://docs.python.org/py3k/library/functions.html#eval
# @see http://www.aspdev.org/asp/asp-eval-execute/
# @see http://en.wikipedia.org/wiki/Eval#Ruby
class Arachni::Checks::CodeInjectionTiming < Arachni::Check::Base

    prefer :code_injection

    def self.payloads
        @payloads ||= {
            ruby:   'sleep(__TIME__/1000);',
            php:    'sleep(__TIME__/1000);',
            perl:   'sleep(__TIME__/1000);',
            python: 'import time;time.sleep(__TIME__/1000);',
            java:   'Thread.sleep(__TIME__);',
            asp:    'Thread.Sleep(__TIME__);',
        }.inject({}) do |h, (platform, payload)|
            h[platform] = [ ' %s', ';%s', "\";%s#", "';%s#" ].map { |s| s % payload }
            h
        end
    end

    def run
        audit_timeout( self.class.payloads, format: [Format::STRAIGHT], timeout: 4000 )
    end

    def self.info
        {
            name:        'Code injection (timing)',
            description: %q{
Injects code snippets and assess whether or not the injection was successful using
a time delay.
},
            elements:    ELEMENTS_WITH_INPUTS,
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.3.2',
            platforms:   payloads.keys,

            issue:       {
                name:            %q{Code injection (timing attack)},
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

By injecting server-side code that is known to take a specific amount of time to
execute, Arachni was able to detect time-based code injection. This indicates that
proper input sanitisation is not occurring.
},
                references:  {
                    'PHP'    => 'http://php.net/manual/en/function.eval.php',
                    'Perl'   => 'http://perldoc.perl.org/functions/eval.html',
                    'Python' => 'http://docs.python.org/py3k/library/functions.html#eval',
                    'ASP'    => 'http://www.aspdev.org/asp/asp-eval-execute/',
                    'Ruby'   => 'http://en.wikipedia.org/wiki/Eval#Ruby'
                },
                tags:            %w(code injection timing blind),
                cwe:             94,
                severity:        Severity::HIGH,
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
