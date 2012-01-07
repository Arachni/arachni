=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Modules

#
# XSS audit module
#
# It doesn't just look for the injected XSS string in the HMTL code
# but actually parses the code and looks for the injected element proper.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.3.1
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
#
class XSS < Arachni::Module::Base

    include Arachni::Module::Utilities

    def prepare
        @_tag_name = 'some_dangerous_input_' + seed
        @_injection_strs = [
            # straight injection
            '<' + @_tag_name + ' />',
            # go for an error
            '\'-;<' + @_tag_name + ' />',
            # break out of HTML comments
            '--> <' + @_tag_name + ' /> <!--',
        ]
        @_opts = {
            :format => [ Format::APPEND | Format::STRAIGHT ],
            :flip_param => true
        }
    end

    def run

        opts = @_opts.dup
        @_injection_strs.each {
            |str|

            opts[:match] = opts[:substring] = str

            audit( str, opts ) {
                |res, opts|
                check_and_log( res, opts )
            }
        }
    end

    def check_and_log( res, opts )
        doc = Nokogiri::HTML( res.body )

        # see if we managed to successfully inject our element
        if !doc.xpath( "//#{@_tag_name}" ).empty?
            opts[:match] = opts[:injected]
            log( opts, res )
        end
    end

    def self.info
        {
            :name           => 'XSS',
            :description    => %q{Cross-Site Scripting module.
                It doesn't just look for the injected XSS string in the HMTL code
                but actually parses the code and looks for the injected element proper.
            },
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE,
                Issue::Element::HEADER
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.3.1',
            :references     => {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Cross-Site Scripting (XSS)},
                :description => %q{Client-side code (like JavaScript) can
                    be injected into the web application which is then returned to the user's browser.
                    This can lead to a compromise of the client's system or serve as a pivoting point for other attacks.},
                :tags        => [ 'xss', 'regexp', 'injection', 'script' ],
                :cwe         => '79',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '9.0',
                :remedy_guidance    => 'User inputs must be validated and filtered
                    before being returned as part of the HTML code of a page.',
                :remedy_code => '',
            }

        }
    end

end
end
end
