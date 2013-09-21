=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# XSS audit module
#
# It doesn't just look for the injected XSS string in the HTML code
# but actually parses the code and looks for the injected element proper.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.3.2
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
#
class Arachni::Modules::XSS < Arachni::Module::Base

    def self.tag
        @tag ||= 'some_dangerous_input_' + seed
    end

    def self.strings
        @strings ||= [
            # straight injection
            '<' + tag + '/>',
            # go for an error
            '\'-;<' + tag + '/>',
            # break out of HTML comments
            '--> <' + tag + '/> <!--',
        ]
    end

    def self.opts
        @opts ||= {
            format:     [Format::APPEND | Format::STRAIGHT],
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
                It doesn't just look for the injected XSS string in the HMTL code
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
