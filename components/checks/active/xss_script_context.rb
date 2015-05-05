=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Injects JS taint code and checks to see if it gets executed as proof of
# vulnerability.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.2.1
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
        @strings << "*/;\n#{seed}/*"

        # In case they're placed as assoc array values.
        @strings << seed
        @strings << "\",x:#{seed},y:\""
        @strings << "',x:#{seed},y:'"

        @strings << "</script><script>#{seed}</script>"
    end

    def self.options
        @options ||= { format: [ Format::STRAIGHT ] }
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
            description: %q{
Injects JS taint code and check to see if it gets executed as proof of vulnerability.
},
            elements:    [ Element::Form, Element::Link, Element::Cookie,
                           Element::Header, Element::LinkTemplate ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:     '0.2.1',

            issue:       {
                name:            %q{Cross-Site Scripting (XSS) in script context},
                description:     %q{
Client-side scripts are used extensively by modern web applications.
They perform from simple functions (such as the formatting of text) up to full
manipulation of client-side data and Operating System interaction.

Cross Site Scripting (XSS) allows clients to inject scripts into a request and
have the server return the script to the client in the response. This occurs
because the application is taking untrusted data (in this example, from the client)
and reusing it without performing any validation or sanitisation.

If the injected script is returned immediately this is known as reflected XSS.
If the injected script is stored by the server and returned to any client visiting
the affected page, then this is known as persistent XSS (also stored XSS).

Arachni has discovered that it is possible to force the page to execute custom
JavaScript code.
},
                references:  {
                    'ha.ckers' => 'http://ha.ckers.org/xss.html',
                    'Secunia'  => 'http://secunia.com/advisories/9716/'
                },
                tags:            %w(xss script dom injection),
                cwe:             79,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
To remedy XSS vulnerabilities, it is important to never use untrusted or unfiltered
data within the code of a HTML page.

Untrusted data can originate not only form the client but potentially a third
party or previously uploaded file etc.

Filtering of untrusted data typically involves converting special characters to
their HTML entity encoded counterparts (however, other methods do exist, see references).
These special characters include:

* `&`
* `<`
* `>`
* `"`
* `'`
* `/`

An example of HTML entity encoding is converting `<` to `&lt;`.

Although it is possible to filter untrusted input, there are five locations
within an HTML page where untrusted input (even if it has been filtered) should
never be placed:

1. Directly in a script.
2. Inside an HTML comment.
3. In an attribute name.
4. In a tag name.
5. Directly in CSS.

Each of these locations have their own form of escaping and filtering.

_Because many browsers attempt to implement XSS protection, any manual verification
of this finding should be conducted using multiple different browsers and browser
versions._
}
            }
        }
    end

end
