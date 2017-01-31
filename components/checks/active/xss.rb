=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

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
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
class Arachni::Checks::Xss < Arachni::Check::Base

    def self.tag_name
        "#{shortname}_#{random_seed}"
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

            # Break out of HTML comments and text areas.
            "</textarea>-->#{tag}<!--<textarea>"
        ].map{ |p| [p, Form.encode( p ) ]}.flatten.uniq
    end

    def self.options
        @options ||= {
            format: [Format::APPEND]
        }
    end

    def self.optimization_cache
        @optimization_cache ||= {}
    end
    def optimization_cache
        self.class.optimization_cache
    end

    def run
        audit( self.class.strings, self.class.options ) do |response, element|
            next if !response.html?

            # If there's no vuln responses will usually be identical, so bail
            # out early.
            # If responses aren't identical due to noise, well, we're not losing
            # much.
            k = "#{response.url.hash}-#{response.body.hash}".hash
            next if optimization_cache[k] == :checked

            optimization_cache[k] = check_and_log( response, element )
        end
    end

    def check_and_log( response, element )
        # Bail out if the response is not tainted unless we're dealing with a Link.
        # The other cases either don't matter or are covered by the xss_dom check.
        if (self.class.elements - [Arachni::Link]).include?( element.class ) &&
            !response.body.downcase.include?( self.class.tag )

            return :checked
        end

        # See if we managed to successfully inject our element in the doc tree.
        if self.class.find_proof( response )
            log vector: element, proof: self.class.tag, response: response
            return :checked
        end

        # No idea what was returned, but we can't work with it.
        return :checked if !response.to_page.has_script?

        with_browser_cluster do |cluster|
            print_info 'Progressing to deferred browser evaluation of response.'

            # Pass the response to the BrowserCluster for evaluation and see if the
            # element appears in the doc tree now.
            cluster.trace_taint(
                response,
                {
                    taint: self.class.tag,
                    args:  [element, page]
                },
                self.class.check_browser_result_cb
            )
        end
    end

    def self.check_browser_result( result, element, referring_page, cluster )
        page = result.page

        # At this point further checks will be body based, identical
        # bodies will yield identical results.
        key = "traced-#{page.body.hash}".hash
        return if optimization_cache[key] == :traced
        optimization_cache[key] = :traced

        print_info 'Checking results of deferred taint analysis.'

        return if !(proof = find_proof( page ))

        log(
            vector:         element,
            proof:          proof,
            page:           page,
            referring_page: referring_page
        )
    end

    def self.check_browser_result_cb
        @check_browser_result_cb ||= method(:check_browser_result)
    end

    def self.find_proof( resource )
        return if !resource.body.has_html_tag?( self.tag_name )

        proof_nodes = Arachni::Parser.parse(
            resource.body,
            whitelist:     [self.tag_name, 'textarea'],
            stop_on_first: [self.tag_name]
        ).nodes_by_name( self.tag_name )

        return if proof_nodes.empty?

        proof = proof_nodes.find do |e|
            e.parent.name != :textarea
        end

        return if !proof

        proof
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
            version:     '0.4.9',

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
                    'Secunia' => 'http://secunia.com/advisories/9716/',
                    'WASC'    => 'http://projects.webappsec.org/w/page/13246920/Cross%20Site%20Scripting',
                    'OWASP'   => 'https://www.owasp.org/index.php/XSS_%28Cross_Site_Scripting%29_Prevention_Cheat_Sheet'
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
