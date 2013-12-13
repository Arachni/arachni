=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Blind SQL injection check
#
# It uses differential analysis to determine how different inputs affect the
# behavior of the web application and checks if the displayed behavior is
# consistent with that of a vulnerable application
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.4.2
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://capec.mitre.org/data/definitions/7.html
# @see http://www.owasp.org/index.php/Blind_SQL_Injection
class Arachni::Checks::BlindDifferentialSQLInjection < Arachni::Check::Base

    prefer :sqli

    def self.queries_for_expression( expression )
        (@templates ||= read_file( 'payloads.txt' )).map do |template|
            [ '\'', '"', '' ].map do |quote|
                template.gsub( '%q%', quote ) + " #{expression.gsub( '%q%', quote )}"
            end
        end.flatten
    end

    # Options holding fault and boolean injection seeds.
    def self.options
        return @options if @options

        pairs  = []
        falses = queries_for_expression( '1=%q%2' )

        queries_for_expression( '1=%q%1' ).each.with_index do |true_expr, i|
            pairs << { true_expr => falses[i] }
        end

        @options = { false: '-1', pairs: pairs }
    end

    def run
        audit_differential self.class.options
    end

    def self.info
        {
            name:        'Blind SQL Injection (differential analysis)',
            description: %q{It uses differential analysis to determine how different inputs affect
                the behavior of the web application and checks if the displayed behavior is consistent
                with that of a vulnerable application.},
            elements:    [ Element::Link, Element::Form, Element::Cookie ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.4.2',
            targets:     %w(Generic),

            issue:       {
                name:            %q{Blind SQL Injection (differential analysis)},
                description:     %q{SQL code can be injected into the web application
    even though it may not be obvious due to suppression of error messages.},
                references:  {
                    'OWASP'         => 'http://www.owasp.org/index.php/Blind_SQL_Injection',
                    'MITRE - CAPEC' => 'http://capec.mitre.org/data/definitions/7.html'
                },
                tags:            %w(sql blind differential injection database),
                cwe:             89,
                severity:        Severity::HIGH,
                remedy_guidance: %q{Suppression of error messages leads to
    security through obscurity which is not a good practise.
    The web application needs to enforce stronger validation
    on user inputs.}
            }

        }
    end

end
