=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Arachni::Checks::XssDomInputs < Arachni::Check::Base

    INPUTS = Set.new([:input, :textarea])

    def tag_name
        "some_dangerous_input_#{random_seed}"
    end

    def tag
        # The trailing space is important, keypress and keyup events are always
        # one character short.
        "<#{tag_name}></#{tag_name}> "
    end

    def run
        # If the page doesn't contain any supported inputs don't bother.
        return if !page.document ||
            !INPUTS.find { |type| page.document.css( type.to_s ).any? }

        with_browser do |browser|
            browser.load( page ).each_element_with_events do |locator, events|
                next if !INPUTS.include? locator.tag_name
                events.each do |event, _|

                    # Instead of working with the same browser we do it this way
                    # in order to distribute the workload via the browser cluster.
                    with_browser do |b|
                        b.javascript.taint = self.tag
                        b.load page

                        transition = b.fire_event( locator, event, value: self.tag )
                        next if !transition

                        p = b.to_page
                        p.dom.transitions << transition

                        check_and_log p
                    end
                end
            end
        end
    end

    def check_and_log( page )
        return if !(proof = find_proof( page ))
        log(
            vector: Element::GenericDOM.new(
                url:        page.url,
                transition: page.dom.transitions.last
            ),
            proof:  proof,
            page:   page
        )
    end

    def find_proof( page )
        proof = page.document.css( self.tag_name )
        return if proof.empty?
        proof.to_s
    end

    def self.info
        {
            name:        'DOM XSS via input field',
            description: %q{
Injects an HTML element into page text fields, triggers their associated events
and inspects the DOM for proof of vulnerability.
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            elements:    [Element::GenericDOM],

            issue:       {
                name:            %q{DOM-based Cross-Site Scripting (XSS) via input fields},
                description:     %q{
Client-side scripts are used extensively by modern web applications.
They perform both simple functions (such as the formatting of text) up to full
manipulation of client side data and operating system interaction.

Unlike traditional Cross Site Scripting (XSS), where the client is able to inject
scripts into a request and have the server return the script to the client, DOM
XSS does not require that a request be sent to the server and may be abused entirely
within the loaded page.

This occurs when elements of the DOM (known as the sources) are able to be
manipulated to contain untrusted data.
The client-side scripts (known as the sinks) in the affected page use or execute
the untrusted data in an unsafe way.

A common attack used by cyber-criminals is to steal a client's session token by
injecting JavaScript, however DOM XSS vulnerabilities can also be abused to exploit
clients.

Arachni has discovered that by inserting an HTML element into the pages DOM inputs
(sources) it was possible to then have the HTML element rendered as part of the
page by the sink.
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
Client side document rewriting, redirection, or other sensitive actions using
untrusted data should be avoided wherever possible as these may not be inspected
by server side filtering.

To remedy DOM XSS vulnerabilities where these sensitive document actions must be
used it is essential to:

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
