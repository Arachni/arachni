=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# It's designed to work with PHP, Perl, Python, Java, ASP and Ruby
# but still needs some more testing.
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://cwe.mitre.org/data/definitions/94.html
# @see http://php.net/manual/en/function.eval.php
# @see http://perldoc.perl.org/functions/eval.html
# @see http://docs.python.org/py3k/library/functions.html#eval
# @see http://www.aspdev.org/asp/asp-eval-execute/
# @see http://en.wikipedia.org/wiki/Eval#Ruby
class Arachni::Checks::CodeInjection < Arachni::Check::Base

    def self.rand1
        @rand1 ||= '28763'
    end

    def self.rand2
        @rand2 ||= '4196403'
    end

    def self.options
        @options ||= {
            signatures: (rand1.to_i * rand2.to_i).to_s,
            format:     [Format::STRAIGHT]
        }
    end

    def self.code_strings
        # code strings to be injected to the webapp
        @code_strings ||= {
            php:    "print #{rand1}*#{rand2};",
            perl:   "print #{rand1}*#{rand2};",
            python: "print #{rand1}*#{rand2}",
            asp:    "Response.Write\x28#{rand1}*#{rand2}\x29"
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
            description: %q{
Injects code snippets and assess whether or not execution was successful.
},
            elements:    ELEMENTS_WITH_INPUTS,
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.2.5',
            platforms:   payloads.keys,

            issue:       {
                name:            %q{Code injection},
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

Arachni was able to inject specific server-side code and have the executed output
from the code contained within the server response. This indicates that proper input
sanitisation is not occurring.
},
                references:  {
                    'PHP'    => 'http://php.net/manual/en/function.eval.php',
                    'Perl'   => 'http://perldoc.perl.org/functions/eval.html',
                    'Python' => 'http://docs.python.org/py3k/library/functions.html#eval',
                    'ASP'    => 'http://www.aspdev.org/asp/asp-eval-execute/',
                },
                tags:            %w(code injection regexp),
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
