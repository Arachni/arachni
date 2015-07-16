=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.2
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
        return if !page.document

        # Everything past this point requires inputs to be present.
        return if !page.has_elements?( INPUTS.to_a )

        # Fill in inputs and trigger their associated events.
        trigger_inputs

        return if !page.has_elements?( :button )

        # Fill in inputs and hit buttons.
        trigger_buttons
    end

    def trigger_inputs
        with_browser do |browser|
            browser.load( page ).each_element_with_events do |locator, events|

                locator_id = "#{page.url}:#{locator.css}"
                next if !INPUTS.include?( locator.tag_name ) || audited?( locator_id )
                audited locator_id

                filter_events( locator.tag_name, events ).each do |event, _|

                    print_status "Scheduling '#{event}' on '#{locator}'"

                    # Instead of working with the same browser we do it this way
                    # in order to distribute the workload via the browser cluster.
                    with_browser do |b|
                        print_status "Triggering '#{event}' on '#{locator}'"

                        b.javascript.taint = self.tag_name
                        b.load page

                        transition = b.fire_event( locator, event, value: self.tag )
                        if !transition
                            print_bad "Could not '#{event}' on '#{locator}'"
                            next
                        end

                        # Page may be out of scope, some sort of JS redirection.
                        if !(p = b.to_page)
                            print_bad "Could not capture page snapshot after '#{event}' on '#{locator}'"
                        end

                        p.dom.transitions << transition

                        check_and_log( p )

                        print_status "Finished '#{event}' on '#{locator}'"
                    end
                end
            end
        end
    end

    def trigger_buttons
        with_browser do |browser|
            browser.load( page ).each_element_with_events do |locator, events|

                locator_id = "#{page.url}:#{locator.css}"
                next if locator.tag_name != :button || audited?( locator_id )
                audited locator_id

                events.each do |event, _|
                    print_status "Scheduling '#{event}' on '#{locator}' after filling in inputs"

                    with_browser do |b|
                        print_status "Triggering '#{event}' on '#{locator}' after filling in inputs"

                        b.javascript.taint = self.tag_name
                        b.load page

                        transitions = fill_in_inputs( b )
                        if transitions.empty?
                            print_bad "Could not fill in any inputs for '#{event}' on '#{locator}'"
                            next
                        end

                        transition = b.fire_event( locator, event )
                        if !transition
                            print_bad "Could not '#{event}' on '#{locator}'"
                            next
                        end

                        transitions << transition

                        # Page may be out of scope, some sort of JS redirection.
                        if !(p = b.to_page)
                            print_bad "Could not capture page snapshot after '#{event}' on '#{locator}'"
                        end

                        transitions.each do |t|
                            p.dom.transitions << t
                        end

                        check_and_log( p )

                        print_status "Finished '#{event}' on '#{locator}' after filling in inputs"
                    end
                end
            end
        end
    end

    def fill_in_inputs( browser )
        transitions = []

        INPUTS.each do |tag|
            browser.watir.send("#{tag}s").each do |locator|
                print_status "Filling in '#{locator.opening_tag}'"

                transitions << fill_in_input( browser, locator )
            end
        end

        transitions.compact
    end

    def fill_in_input( browser, locator )
        browser.fire_event( locator, :input, value: self.tag )
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
        return if !page.has_elements?( self.tag_name )

        proof = page.document.css( self.tag_name )
        return if proof.empty?

        proof.to_s
    end

    def filter_events( element, events )
        supported = Set.new( Arachni::Browser::Javascript.events_for( element ) )
        events.reject { |name, _| !supported.include? ('on' + name.to_s.gsub( /^on/, '' )).to_sym }
    end

    def self.info
        {
            name:        'DOM XSS via input field',
            description: %q{
Injects an HTML element into page text fields, triggers their associated events
and inspects the DOM for proof of vulnerability.
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.2',
            elements:    [Element::GenericDOM],

            issue:       {
                name:            %q{DOM-based Cross-Site Scripting (XSS) via input fields},
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
