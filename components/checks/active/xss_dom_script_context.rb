=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Arachni::Checks::XSSDOMScriptContext < Arachni::Check::Base

    prefer :xss_script_context

    def self.seed
        'window.top._%s_taint_tracer.log_execution_flow_sink()'
    end

    def self.strings
        @strings ||= [
            "javascript:#{seed}//",
            "1;#{seed}//",
            "';#{seed}//",
            "\";#{seed}//",
            "*/;#{seed}/*"
        ]
    end

    def self.options
        @options ||= { format: [ Format::STRAIGHT, Format::APPEND ] }
    end

    def taints
        @taints ||= self.class.strings.
            map { |taint| taint % browser_cluster.javascript_token }
    end

    def seed
        self.class.seed % browser_cluster.javascript_token
    end

    def run
        return if !browser_cluster

        each_candidate_dom_element do |element|
            element.dom.audit(
                taints,
                self.class.options.merge( submit: { taint: seed } ),
                &method(:check_and_log)
            )
        end
    end

    def check_and_log( page, element )
        return if page.dom.execution_flow_sinks.empty?
        log vector: element, proof: element.seed, page: page
    end

    def self.info
        {
            name:        'DOM XSS in script context',
            description: %q{Injects JS taint code and checks to see if it gets
                executed as proof of vulnerability.},
            elements:    [Element::Form::DOM, Element::Link::DOM,
                          Element::Cookie::DOM, Element::LinkTemplate::DOM ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',

            issue:       {
                name:            %q{DOM-based Cross-Site Scripting (XSS)},
                description:     %q{Client-side code (like JavaScript) can
    be injected into the web application which is then returned to the user's browser.
    This can lead to a compromise of the client's system or serve as a pivoting point for other attacks.},
                references:  {
                    'ha.ckers' => 'http://ha.ckers.org/xss.html',
                    'Secunia'  => 'http://secunia.com/advisories/9716/'
                },
                tags:            %w(xss dom injection script),
                cwe:             79,
                severity:        Severity::HIGH,
                remedy_guidance: 'User inputs must be validated and filtered
    before being returned as part of the HTML code of a page.'
            }
        }
    end

end
