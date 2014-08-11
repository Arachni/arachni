=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Arachni::Checks::BlindDifferentialNoSQLInjection < Arachni::Check::Base

    def self.options
        return @options if @options

        pairs  = []
        [ '\'', '"', '' ].each do |q|
            {
                '%q;return true;var foo=%q' => '%q;return false;var foo=%q',
                '1%q||this%q'               => '1%q||!this%q'
            }.each do |s_true, s_false|
                pairs << { s_true.gsub( '%q', q ) => s_false.gsub( '%q', q ) }
            end
        end

        @options = { false: '-1', pairs: pairs }
    end

    def run
        audit_differential self.class.options
    end

    def self.info
        {
            name:        'Blind NoSQL Injection (differential analysis)',
            description: %q{
It uses differential analysis to determine how different inputs affect the behavior
of the web application and checks if the displayed behavior is consistent with
that of a vulnerable application.
},
            elements:    [ Element::Link, Element::Form, Element::Cookie ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',

            issue:       {
                name:            %q{Blind NoSQL Injection (differential analysis)},
                description:     %q{
A NoSQL injection occurs when a value originating from the client's request is
used within a NoSQL call without prior sanitisation.

This can allow cyber-criminals to execute arbitrary NoSQL code and thus steal data,
or use the additional functionality of the database server to take control of the
server.

Arachni discovered that the affected page and parameter are vulnerable. This
injection was detected as Arachni was able to inject specific NoSQL queries that
if vulnerable result in the responses for each injection being different. This is
known as a blind NoSQL injection vulnerability.
},
                tags:            %w(nosql blind differential injection database),
                references:  {
                    'OWASP' => 'https://www.owasp.org/index.php/Testing_for_NoSQL_injection'
                },
                cwe:             89,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
The most effective remediation against NoSQL injection attacks is to ensure that
NoSQL API calls are not constructed via string concatenation.

Doing this within the server side code will ensure that any escaping is handled
by the underlying framework. Depending on the NoSQL database being used, this
may not be possible, in which case all untrusted data sources must be escaped correctly.

This is best achieved by using existing escaping libraries.
}
            }

        }
    end

end
