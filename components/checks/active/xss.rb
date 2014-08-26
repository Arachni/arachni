=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Injects an HTML element into page inputs and then parses the HTML markup of
# tainted responses to look for proof of vulnerability.
#
# If this rudimentary check fails, tainted responses are forwarded to the
# {BrowserCluster} for evaluation and {#trace_taint taint-tracing}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.4
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
class Arachni::Checks::Xss < Arachni::Check::Base

    def self.tag_name
        "some_dangerous_input_#{random_seed}"
    end

    def self.tag
        "<#{tag_name}/>"
    end

    def self.strings
        @strings ||= [
            # Straight injection.
            tag,

            # Go for an error.
            "()\"&%1'-;#{tag}'",

            # Break out of HTML comments.
            "-->#{tag}<!--"
        ]
    end

    def self.options
        @options ||= {
            format:     [Format::APPEND],
            flip_param: true
        }
    end

    def run
        audit( self.class.strings, self.class.options ) do |response, element|
            check_and_log( response, element )
        end
    end

    def check_and_log( response, element )
        # if the body doesn't include the tag at all bail out early
        return if !response.body.downcase.include?( self.class.tag )

        print_info 'Response is tainted, looking for proof of vulnerability.'

        # See if we managed to successfully inject our element in the doc tree.
        if find_proof( response )
            log vector: element, proof: self.class.tag, response: response
            return
        end

        with_browser_cluster do
            print_info 'Progressing to deferred browser evaluation of response.'

            # Pass the response to the BrowserCluster for evaluation and see if the
            # element appears in the doc tree now.
            trace_taint( response, taint: self.class.tag ) do |page|
                print_info 'Checking results of deferred taint analysis.'

                next if !(proof = find_proof( page ))
                log vector: element, proof: proof, page: page
            end
        end
    end

    def find_proof( resource )
        proof = Nokogiri::HTML( resource.body ).css( self.class.tag_name )
        return if proof.empty?
        proof.to_s
    end

    def self.info
        {
            name:        'XSS',
            description: %q{
Injects an HTML element into page inputs and then parses the HTML markup of
tainted responses to look for proof of vulnerability.
},
            elements:    [Element::Form, Element::Link, Element::Cookie,
                          Element::Header, Element::LinkTemplate],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:     '0.4',

            issue:       {
                name:            %q{Cross-Site Scripting (XSS)},
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
HTML element content.
},
                references:  {
                    'ha.ckers' => 'http://ha.ckers.org/xss.html',
                    'Secunia'  => 'http://secunia.com/advisories/9716/',
                    'WASC' => 'http://projects.webappsec.org/w/page/13246920/Cross%20Site%20Scripting',
                    'OWASP' => 'www.owasp.org/index.php/XSS_%28Cross_Site_Scripting%29_Prevention_Cheat_Sheet'
                },
                tags:            %w(xss regexp injection script),
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
