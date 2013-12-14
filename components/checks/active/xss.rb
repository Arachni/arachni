=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# XSS  check.
#
# It doesn't just look for the injected XSS string in the HTML code
# but actually parses the code and looks for the injected element proper.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.3.3
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
        self.class.strings.each do |str|
            audit( str, self.class.opts ) { |response, element| check_and_log( response, element ) }
        end
    end

    def check_and_log( response, element )
        # if the body doesn't include the tag name at all bail out early
        return if !response.body || !response.body.include?( self.class.tag )

        # see if we managed to successfully inject our element in the doc tree
        return if Nokogiri::HTML( response.body ).css( self.class.tag_name ).empty?

        log( { vector: element, proof: self.class.tag }, response )
    end

    def self.info
        {
            name:        'XSS',
            description: %q{Cross-Site Scripting check.
                It doesn't just look for the injected XSS string in the HTML code
                but actually parses the code and looks for the injected element proper.
            },
            elements:    [Element::Form, Element::Link, Element::Cookie, Element::Header],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.3.2',
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
