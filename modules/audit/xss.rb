=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules

#
# XSS audit module.<br/>
# It audits links, forms and cookies.
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
#
class XSS < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )

        @results    = []
    end

    def prepare( )
        @_injection_strs = [
            '<arachni_xss_' + seed,
            '<arachni_xss_\'";_' + seed,
        ]
        @_opts = {
            :format => [ Format::APPEND | Format::NULL ],
        }
    end

    def run( )
        @_injection_strs.each {
            |str|

            opts = {
                :match  => str,
                :substring => str
            }.merge( @_opts )

            audit( str, opts )
        }
    end

    def self.info
        {
            :name           => 'XSS',
            :description    => %q{Cross-Site Scripting module},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE,
                Issue::Element::HEADER
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.2',
            :references     => {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Cross-Site Scripting (XSS)},
                :description => %q{Client-side code, like JavaScript, can
                    be injected into the web application.},
                :cwe         => '79',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '9.0',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

end
end
end
