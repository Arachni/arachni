=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Arachni::Checks::BlindDifferentialNoSQLInjection < Arachni::Check::Base

    def self.options
        return @options if @options

        pairs  = []
        [ '\'', '"', '' ].each do |q|
            {
                ';return true;var foo=' => ';return false;var foo=',
                '||this||'              => '||!this||'
            }.each do |s_true, s_false|
                pairs << { "#{q}#{s_true}#{q}" => "#{q}#{s_false}#{q}" }
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
            description: %q{It uses differential analysis to determine how different inputs affect
                the behavior of the web application and checks if the displayed behavior is consistent
                with that of a vulnerable application.},
            elements:    [ Element::Link, Element::Form, Element::Cookie ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',

            issue:       {
                name:            %q{Blind NoSQL Injection (differential analysis)},
                description:     %q{NoSQL code can be injected into the web application
    even though it may not be obvious due to suppression of error messages.},
                tags:            %w(nosql blind differential injection database),
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
