=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Injects JS taint code and checks to see if it gets executed as proof of
# vulnerability.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
class Arachni::Checks::XssScriptContext < Arachni::Check::Base

    def self.seed
        'window.top._%s_taint_tracer.log_execution_flow_sink()'
    end

    def self.strings
        @strings ||= [
            "javascript:#{seed}//",
            "1;#{seed}//",
            "';#{seed}//",
            "\";#{seed}//",
            "1;\n#{seed}//",
            "*/;\n#{seed}/*"
        ]
    end

    def self.options
        @options ||= { format: [ Format::STRAIGHT, Format::APPEND ] }
    end

    def taints
        self.class.strings.map { |taint| taint % browser_cluster.javascript_token }
    end

    def run
        audit( taints, self.class.options ) do |response, element|
            check_and_log( response, element )
        end
    end

    def check_and_log( response, element )
        # Check to see if the response is tainted before going any further.
        return if element.seed.to_s.empty? || !response.body ||
            !response.body.include?( element.seed )

        print_info 'Response is tainted, scheduling a taint-trace.'

        # Pass the response to the BrowserCluster for evaluation and see if the
        # element appears in the doc tree now.
        trace_taint( response, taint: self.class.seed ) do |page|
            print_info 'Checking results of deferred taint analysis for' <<
                           ' execution-flow sink data.'

            next if page.dom.execution_flow_sink.empty?

            log( { vector: element, proof: element.seed }, page )
        end
    end

    def self.info
        {
            name:        'XSS in script context',
            description: %q{Injects JS taint code and check to see if it gets
                executed as proof of vulnerability.},
            elements:    [Element::Form, Element::Link, Element::Cookie, Element::Header],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2',
            targets:     %w(Generic),

            issue:       {
                name:            %q{Cross-Site Scripting in HTML \'script\' tag},
                description:     %q{Unvalidated user input is being embedded inside an executable JS context.
    This makes Cross-Site Scripting attacks much easier to mount since user input lands inside
    a trusted script.},
                references:  {
                    'ha.ckers' => 'http://ha.ckers.org/xss.html',
                    'Secunia'  => 'http://secunia.com/advisories/9716/'
                },
                tags:            %w(xss script dom injection),
                cwe:             79,
                severity:        Severity::HIGH,
                remedy_guidance: 'User inputs must be validated and filtered
    before being included in executable code or not be included at all.'
            }
        }
    end

end
