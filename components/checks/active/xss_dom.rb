=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1
class Arachni::Checks::XSSDOM < Arachni::Check::Base
    prefer :xss

    def self.tag_name
        "some_dangerous_input_#{seed}"
    end

    def self.tag
        "<#{tag_name}/>"
    end

    def self.strings
        @strings ||= [
            # Straight injection.
            tag,

            # Break out of HTML comments.
            "-->#{tag}<!--"
        ]
    end

    def self.options
        @options ||= {
            format: [ Format::APPEND ],
            submit: { taint: tag_name }
        }
    end

    def run
        return if !browser_cluster

        each_candidate_dom_element do |element|
            element.dom.audit( self.class.strings, self.class.options, &method(:check_and_log) )
        end
    end

    def check_and_log( page, element )
        return if !(proof = find_proof( page ))
        # ap page.dom.data_flow_sink
        # ap page.dom.transitions
        log vector: element, proof: proof, page: page
    end

    def find_proof( page )
        proof = page.document.css( self.class.tag_name )
        return if proof.empty?
        proof.to_s
    end


    def self.info
        {
            name:        'DOM XSS',
            description: %q{Injects an HTML element into page DOM inputs and then
                parses the HTML markup of tainted responses to look for proof of vulnerability.},
            elements:    [Element::Form::DOM, Element::Link::DOM],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',

            issue:       {
                name:            %q{DOM-based Cross-Site Scripting (XSS)},
                description:     %q{Client-side code (like JavaScript) can
    be injected into the web application which is then returned to the user's browser.
    This can lead to a compromise of the client's system or serve as a pivoting point for other attacks.},
                references:  {
                    'ha.ckers' => 'http://ha.ckers.org/xss.html',
                    'Secunia'  => 'http://secunia.com/advisories/9716/'
                },
                tags:            %w(xss dom injection script),
                cwe:             79,
                severity:        Severity::HIGH,
                remedy_guidance: 'User inputs must be validated and filtered
    before being returned as part of the HTML code of a page.'
            }
        }
    end

end
