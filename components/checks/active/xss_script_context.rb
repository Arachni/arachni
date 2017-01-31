=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Injects JS taint code and checks to see if it gets executed as proof of
# vulnerability.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
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

        # Not an event attribute so it gets special treatment by being checked
        # for a "script:" prefix.
        'src'
    ]

    class SAX
        attr_reader :tainted

        def initialize( seed )
            @seed       = seed
            @attributes = Set.new( ATTRIBUTES )
        end

        def document
        end

        def tainted?
            !!@tainted
        end

        def start_element( name )
            @in_script = (name.to_s.downcase == 'script')
        end

        def end_element( name )
            @in_script = false
        end

        def attr( name, value )
            name  = name.to_s.downcase
            value = value.downcase

            return if !@attributes.include?( name )

            if name == 'src'
                if @seed.start_with?( 'javascript:' ) && value == @seed
                    @tainted = true
                    fail Arachni::Parser::SAX::Stop
                end
            else
                if value == @seed
                    @tainted = true
                    fail Arachni::Parser::SAX::Stop
                end
            end

            if value.include?( @seed )
                @tainted = true
                fail Arachni::Parser::SAX::Stop
            end
        end

        def text( value )
            return if !@in_script || value !~ /#{Regexp.escape( @seed )}/i

            @tainted = true
            fail Arachni::Parser::SAX::Stop
        end
    end

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

    def self.optimization_cache
        @optimization_cache ||= {}
    end
    def optimization_cache
        self.class.optimization_cache
    end

    def taints( browser_cluster )
        self.class.strings.map { |taint| taint % browser_cluster.javascript_token }
    end

    def run
        with_browser_cluster do |cluster|
            audit taints( cluster ), self.class.options do |response, element|
                next if !response.html?

                # Completely body based, identical bodies will yield identical
                # results.
                k = "#{response.url.hash}-#{response.body.hash}".hash
                next if optimization_cache[k]
                optimization_cache[k] = true

                check_and_log( response, element )
            end
        end
    end

    def check_and_log( response, element )
        # Check to see if the response is tainted before going any further,
        # this also serves as a rudimentary check for really simple cases.
        return if !(proof = tainted?( response, element.seed ))

        if proof.is_a? String
            log vector: element, proof: element.seed, response: response
            return
        end

        with_browser_cluster do |cluster|
            print_info 'Response is tainted, scheduling a taint-trace.'

            # Pass the response to the BrowserCluster for evaluation and see if the
            # JS payload we injected got executed by inspecting the page's
            # execution-flow sink.
            cluster.trace_taint(
                response,
                {
                    taint: self.class.seed,
                    args:  [element, page]
                },
                self.class.check_browser_result_cb
            )
        end
    end

    def self.check_browser_result( result, element, referring_page, cluster )
        page = result.page

        print_info 'Checking results of deferred taint analysis for' <<
                       ' execution-flow sink data.'

        return if page.dom.execution_flow_sinks.empty?

        log(
            vector:         element,
            proof:          element.seed,
            page:           page,
            referring_page: referring_page
        )
    end

    def self.check_browser_result_cb
        @check_browser_result_cb ||= method(:check_browser_result)
    end

    def tainted?( response, seed )
        return if seed.to_s.empty? || !response.body.to_s.include?( seed )

        handler = SAX.new( self.class.seed % browser_cluster.javascript_token )
        Arachni::Parser.parse( response.body, handler: handler )

        handler.tainted?
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
            version:     '0.2.5',

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
                    'Secunia' => 'http://secunia.com/advisories/9716/',
                    'WASC'    => 'http://projects.webappsec.org/w/page/13246920/Cross%20Site%20Scripting',
                    'OWASP'   => 'https://www.owasp.org/index.php/XSS_%28Cross_Site_Scripting%29_Prevention_Cheat_Sheet'
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
