=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# It injects a string and checks if it appears inside an event attribute of any HTML tag.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
class Arachni::Checks::XssEvent < Arachni::Check::Base

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
        attr_reader :proof

        def initialize( seed )
            @seed       = seed
            @attributes = Set.new( ATTRIBUTES )
        end

        def document
        end

        def attr( name, value )
            name  = name.to_s.downcase
            value = value.downcase

            return if !@attributes.include?( name )

            if name == 'src'
                # Javascript cases can be handled more reliably by the
                # xss_script_context check; VBScript doesn't have full support
                # so we settle.
                if value =~ /^(vb|)script:/ && value.include?( @seed )
                    @proof = value
                    fail Arachni::Parser::SAX::Stop
                end
            elsif value.include?( @seed )
                @proof = value
                fail Arachni::Parser::SAX::Stop
            end
        end
    end

    def self.attribute_name
        'arachni_xss_in_element_event'
    end

    def self.strings
        @strings ||= [
            ";#{attribute_name}=#{random_seed}//",
            "\";#{attribute_name}=#{random_seed}//",
            "';#{attribute_name}=#{random_seed}//"
        ].map { |s| [ " script:#{s}", " #{s}" ] }.flatten
    end

    def self.options
        @options ||= { format: [ Format::APPEND ] }
    end

    def self.optimization_cache
        @optimization_cache ||= {}
    end
    def optimization_cache
        self.class.optimization_cache
    end

    def run
        audit self.class.strings, self.class.options do |response, element|
            next if !response.html?

            k = "#{response.url.hash}-#{response.body.hash}".hash
            next if optimization_cache[k] == :checked

            optimization_cache[k] = check_and_log( response, element )
        end
    end

    def check_and_log( response, element )
        body = response.body

        return :checked if !(body =~ /#{self.class.attribute_name}/i)
        return if element.seed.to_s.empty? || !(body =~ /#{element.seed}/i)

        handler = SAX.new( element.seed.split( ':', 2 ).last )
        Arachni::Parser.parse( body, handler: handler )

        return :checked if !handler.proof

        log vector: element, response: response, proof: handler.proof
    end

    def self.info
        {
            name:        'XSS in HTML element event attribute',
            description: %q{Cross-Site Scripting in event tag of HTML element.},
            elements:    [Element::Form, Element::Link, Element::Cookie, Element::Header],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:     '0.1.9',

            issue:       {
                name:            %q{Cross-Site Scripting (XSS) in event tag of HTML element},
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

Arachni has discovered that it is possible to insert script content directly into
an HTML event attribute. For example `<div onmouseover="x=INJECTION_HERE"</div>`,
where `INJECTION_HERE` represents the location where the Arachni payload was detected.
},
                references:  {
                    'Secunia' => 'http://secunia.com/advisories/9716/',
                    'WASC'    => 'http://projects.webappsec.org/w/page/13246920/Cross%20Site%20Scripting',
                    'OWASP'   => 'https://www.owasp.org/index.php/XSS_%28Cross_Site_Scripting%29_Prevention_Cheat_Sheet'
                },
                tags:            %w(xss event injection dom attribute),
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
