=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

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
        str = '<arachni_xss_' + seed
        @opts = {
            :format => [ Format::APPEND | Format::NULL ],
            :match  => str,
            :regexp => Regexp.new( str )
        }
    end

    def run( )
        audit( @opts[:match], @opts )
    end

    def self.info
        {
            :name           => 'XSS',
            :description    => %q{Cross-Site Scripting recon module},
            :elements       => [
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE,
                Vulnerability::Element::HEADER
            ],
            :author         => 'zapotek',
            :version        => '0.2',
            :references     => {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{Cross-Site Scripting (XSS)},
                :description => %q{Client-side code, like JavaScript, can
                    be injected into the web application.},
                :cwe         => '79',
                :severity    => Vulnerability::Severity::HIGH,
                :cvssv2       => '9.0',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

end
end
end
