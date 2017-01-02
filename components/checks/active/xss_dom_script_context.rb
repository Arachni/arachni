=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::XssDomScriptContext < Arachni::Check::Base

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
        @options ||= { format: [ Format::STRAIGHT ] }
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
            element.audit(
                taints,
                self.class.options.merge( submit: { taint: seed } )
            )
        end
    end

    def self.check_and_log( page, element )
        return if page.dom.execution_flow_sinks.empty?
        log vector: element, page: page
    end

    def self.info
        {
            name:        'DOM XSS in script context',
            description: %q{
Injects JS taint code and checks to see if it gets executed as proof of vulnerability.
},
            elements:    DOM_ELEMENTS_WITH_INPUTS,
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.2',

            issue:       {
                name:            %q{DOM-based Cross-Site Scripting (XSS) in script context},
                description:     %q{
Client-side scripts are used extensively by modern web applications.
They perform from simple functions (such as the formatting of text) up to full
manipulation of client-side data and Operating System interaction.

Unlike traditional Cross-Site Scripting (XSS), where the client is able to inject
scripts into a request and have the server return the script to the client, DOM
XSS does not require that a request be sent to the server and may be abused entirely
within the loaded page.

This occurs when elements of the DOM (known as the sources) are able to be
manipulated to contain untrusted data, which the client-side scripts (known as the
sinks) use or execute an unsafe way.

Arachni has discovered that by modifying the affected DOM source, it is possible
to insert and execute JavaScript code.
},
                references:  {
                    'WASC'  => 'http://projects.webappsec.org/w/page/13246920/Cross%20Site%20Scripting',
                    'OWASP' => 'https://www.owasp.org/index.php/DOM_Based_XSS',
                    'OWASP - Prevention'  => 'https://www.owasp.org/index.php/DOM_based_XSS_Prevention_Cheat_Sheet'
                },
                tags:            %w(xss dom injection script),
                cwe:             79,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
Client-side document rewriting, redirection, or other sensitive action, using
untrusted data, should be avoided wherever possible, as these may not be inspected
by server side filtering.

To remedy DOM XSS vulnerabilities where these sensitive document actions must be
used, it is essential to:

1. Ensure any untrusted data is treated as text, as opposed to being interpreted
    as code or mark-up within the page.
2. Escape untrusted data prior to being used within the page. Escaping methods
    will vary depending on where the untrusted data is being used.
    (See references for details.)
3. Use `document.createElement`, `element.setAttribute`, `element.appendChild`,
    etc. to build dynamic interfaces as opposed to HTML rendering methods such as
    `document.write`, `document.writeIn`, `element.innerHTML`, or `element.outerHTML `etc.
}
            }
        }
    end

end
