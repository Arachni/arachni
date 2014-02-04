=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Injects an HTML element into page inputs and then parses the HTML markup of
# tainted responses to look for proof of vulnerability.
#
# If this rudimentary check fails, tainted responses are forwarded to the
# {BrowserCluster} for evaluation and {#trace_taint taint-tracing}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.4
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
class Arachni::Checks::XSS < Arachni::Check::Base

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

            # Go for an error.
            "()\"&%1'-;#{tag}'",

            # Break out of HTML comments.
            "-->#{tag}<!--"
        ]
    end

    def self.opts
        @opts ||= {
            format:     [Format::APPEND],
            flip_param: true
        }
    end

    def run
        audit( self.class.strings, self.class.opts ) do |response, element|
            check_and_log( response, element )
        end
    end

    def check_and_log( response, element )
        # if the body doesn't include the tag at all bail out early
        return if !response.body || !response.body.include?( self.class.tag )

        print_info 'Response is tainted, looking for proof of vulnerability.'

        # See if we managed to successfully inject our element in the doc tree.
        if find_proof( response )
            log vector: element, proof: self.class.tag, response: response
            return
        end

        print_info 'Progressing to deferred browser evaluation of response.'

        # Pass the response to the BrowserCluster for evaluation and see if the
        # element appears in the doc tree now.
        trace_taint( response, taint: self.class.tag ) do |page|
            print_info 'Checking results of deferred taint analysis.'

            next if !(proof = find_proof( page ))
            log vector: element, proof: proof, page: page
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
            description: %q{Cross-Site Scripting check.
                Injects an HTML element into page inputs and then parses the HTML markup of
                tainted responses to look for proof of vulnerability.
            },
            elements:    [Element::Form, Element::Link, Element::Cookie, Element::Header],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.4',
            targets:     %w(Generic),

            issue:       {
                name:            %q{Cross-Site Scripting (XSS)},
                description:     %q{Client-side code (like JavaScript) can
    be injected into the web application which is then returned to the user's browser.
    This can lead to a compromise of the client's system or serve as a pivoting point for other attacks.},
                references:  {
                    'ha.ckers' => 'http://ha.ckers.org/xss.html',
                    'Secunia'  => 'http://secunia.com/advisories/9716/'
                },
                tags:            %w(xss regexp injection script),
                cwe:             79,
                severity:        Severity::HIGH,
                remedy_guidance: 'User inputs must be validated and filtered
    before being returned as part of the HTML code of a page.'
            }
        }
    end

end
