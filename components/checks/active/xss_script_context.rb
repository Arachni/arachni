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

    ATTRIBUTES = [
        'onload',
        'onunload',
        'onblur',
        'onchange',
        'onfocus',
        'onreset',
        'onselect',
        'onsubmit',
        'onabort',
        'onkeydown',
        'onkeypress',
        'onkeyup',
        'onclick',
        'ondblclick',
        'onmousedown',
        'onmousemove',
        'onmouseout',
        'onmouseover',
        'onmouseup',
        'src'
    ]

    def self.seed
        'window.top._%s_taint_tracer.log_execution_flow_sink()'
    end

    def self.strings
        return @strings if @strings

        @strings ||= [ "javascript:#{seed}" ]

        ['\'', '"', ''].each do |quote|
            [ "%q;#{seed}%q", "%q;#{seed};%q" ].each do |payload|
                @strings << payload.gsub( '%q', quote )
            end
        end

        [ "1;#{seed}%q", "1;\n#{seed}%q" ].each do |payload|
            ['', ';'].each do |s|
                @strings << payload.gsub( '%q', s )
            end
        end

        @strings = @strings.map { |s| [ s, "#{s}//" ] }.flatten
        ap @strings << "*/;\n#{seed}/*"
    end

    def self.options
        @options ||= { format: [ Format::STRAIGHT, Format::APPEND ] }
    end

    def taints( browser_cluster )
        self.class.strings.map { |taint| taint % browser_cluster.javascript_token }
    end

    def run
        with_browser_cluster do |cluster|
            audit taints( cluster ), self.class.options, &method(:check_and_log)
        end
    end

    def check_and_log( response, element )
        # Check to see if the response is tainted before going any further,
        # this also serves as a rudimentary check for really simple cases.
        return if !(proof = tainted?( response, element.seed ))

        if proof.is_a? String
            return log vector: element, proof: element.seed, response: response
        end

        print_info 'Response is tainted, scheduling a taint-trace.'

        # Pass the response to the BrowserCluster for evaluation and see if the
        # JS payload we injected got executed by inspecting the page's
        # execution-flow sink.
        trace_taint( response, taint: self.class.seed ) do |page|
            print_info 'Checking results of deferred taint analysis for' <<
                           ' execution-flow sink data.'

            next if page.dom.execution_flow_sinks.empty?

            log vector: element, proof: element.seed, page: page
        end
    end

    def tainted?( response, seed )
        return if seed.to_s.empty? || !response.body.to_s.include?( seed )

        doc = Nokogiri::HTML( response.body )
        return true if doc.css('script').to_s.include?( seed )

        ATTRIBUTES.each do |attribute|
            doc.xpath( "//*[@#{attribute}]" ).each do |elem|
                value = elem.attributes[attribute].to_s

                if attribute == 'src'
                    return value if seed.start_with?( 'javascript:' ) && value == seed
                else
                    return value if value == seed
                end

                return true  if value.include?( seed )
            end
        end

        false
    end

    def self.info
        {
            name:        'XSS in script context',
            description: %q{Injects JS taint code and check to see if it gets
                executed as proof of vulnerability.},
            elements:    [ Element::Form, Element::Link, Element::Cookie,
                           Element::Header, Element::LinkTemplate ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.2',

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
