=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

# XSS audit module
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
class Arachni::Modules::XSS < Arachni::Module::Base

    def self.tag
        @tag ||= 'some_dangerous_input_' + seed
    end

    def self.strings
        @strings ||= [
            # Straight injection.
            "<#{tag}/>",

            # Go for an error.
            "()\"&%1'-;<#{tag}/>'",

            # Break out of HTML comments.
            "--><#{tag}/><!--"
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
            audit( str, self.class.opts ) { |res, opts| check_and_log( res, opts ) }
        end
    end

    def check_and_log( res, opts )
        # if the body doesn't include the tag name at all bail out early
        return if !res.body || !res.body.include?( self.class.tag )

        # see if we managed to successfully inject our element in the doc tree
        return if Nokogiri::HTML( res.body ).css( self.class.tag ).empty?

        # Nokogiri seems to think that an HTML node inside a textarea is a node
        # and not just text, however I disagree.
        #
        # *But*, there's the possibility of being able to break out of the
        # textarea hence I'll leave this commented and sleep on it.
        #our_nodes.each { |node| return if !node.ancestors( 'textarea' ).empty? }

        opts[:match] = opts[:injected]
        log( opts, res )
    end

    def self.info
        {
            name:        'XSS',
            description: %q{Cross-Site Scripting module.
                It doesn't just look for the injected XSS string in the HTML code
                but actually parses the code and looks for the injected element proper.
            },
            elements:    [Element::FORM, Element::LINK, Element::COOKIE, Element::HEADER],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.3.2',
            references:  {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            targets:     %w(Generic),
            issue:       {
                name:            %q{Cross-Site Scripting (XSS)},
                description:     %q{Client-side code (like JavaScript) can
    be injected into the web application which is then returned to the user's browser.
    This can lead to a compromise of the client's system or serve as a pivoting point for other attacks.},
                tags:            %w(xss regexp injection script),
                cwe:             '79',
                severity:        Severity::HIGH,
                cvssv2:          '9.0',
                remedy_guidance: 'User inputs must be validated and filtered
    before being returned as part of the HTML code of a page.',
            }
        }
    end

end
