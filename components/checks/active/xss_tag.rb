=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# XSS in HTML tag.
# It injects a string and checks if it appears inside any HTML tags.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
class Arachni::Checks::XssTag < Arachni::Check::Base

    ATTRIBUTE_NAME = 'arachni_xss_in_tag'

    class SAX
        attr_reader :landed

        def initialize( seed )
            @seed = seed
        end

        def document
        end

        def landed?
            !!@landed
        end

        def attr( name, value )
            name  = name.to_s.downcase
            value = value.downcase

            return if ATTRIBUTE_NAME != name || value != @seed

            @landed = true
            fail Arachni::Parser::SAX::Stop
        end
    end

    def self.strings
        @strings ||= ['', '\'', '"'].
            map { |q| "#{q} #{ATTRIBUTE_NAME}=#{q}#{random_seed}#{q} blah=#{q}" }
    end

    def run
        audit( self.class.strings, format: [ Format::APPEND ] ) do |response, element|
            check_and_log( response, element )
        end
    end

    def check_and_log( response, element )
        return if !response.html?

        # If we have no body or it doesn't contain the ATTRIBUTE_NAME under any
        # context there's no point in parsing the HTML to verify the vulnerability.
        return if !(response.body =~ /#{ATTRIBUTE_NAME}/i)

        handler = SAX.new( random_seed )
        Arachni::Parser.parse( response.body, handler: handler )
        return if !handler.landed?

        log(
            vector: element,
            proof: find_included_payload( response.body.downcase ).to_s,
            response: response
        )
    end

    def find_included_payload( body )
        self.class.strings.each do |payload|
            return payload if body.include?( payload )
        end
        nil
    end

    def self.info
        {
            name:        'XSS in HTML tag',
            description: %q{Cross-Site Scripting in HTML tag.},
            elements:    [ Element::Form, Element::Link, Element::Cookie, Element::Header ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:     '0.1.11',

            issue:       {
                name:            %q{Cross-Site Scripting (XSS) in HTML tag},
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

Arachni has discovered that it is possible to insert content directly into an HTML
tag. For example `<INJECTION_HERE href=.......etc>` where `INJECTION_HERE`
represents the location where the Arachni payload was detected.
},
                references:  {
                    'Secunia' => 'http://secunia.com/advisories/9716/',
                    'WASC'    => 'http://projects.webappsec.org/w/page/13246920/Cross%20Site%20Scripting',
                    'OWASP'   => 'https://www.owasp.org/index.php/XSS_%28Cross_Site_Scripting%29_Prevention_Cheat_Sheet'
                },

                tags:            %w(xss script tag regexp dom attribute injection),
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
