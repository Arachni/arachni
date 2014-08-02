=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Arachni::Checks::XSSDOMInputs < Arachni::Check::Base

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
        # ap page.dom.transitions
        # puts proof
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
            description: %q{Injects an HTML element into page text fields, triggers
                their associated events and inspects the DOM for proof of vulnerability.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            elements:    [Element::GenericDOM],

            issue:       {
                name:            %q{DOM-based Cross-Site Scripting (XSS) via input fields},
                description:     %q{Client-side code (like JavaScript) can
                    be injected into the web application by placing it inside an input field
                    and triggering one of the DM events associated with it.},
                references:  {
                    'ha.ckers' => 'http://ha.ckers.org/xss.html',
                    'Secunia'  => 'http://secunia.com/advisories/9716/'
                },
                tags:            %w(xss dom injection script),
                cwe:             79,
                severity:        Severity::HIGH,
                remedy_guidance: 'User inputs must be validated and filtered
                    before being added to the DOM.'
            }
        }
    end

end
