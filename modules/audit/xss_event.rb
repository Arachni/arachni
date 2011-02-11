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
# XSS in HTML element event attribute. <br/>
# It injects a string and checks if it appears inside an event attribute of any HTML tag.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
#
class XSSEvent < Arachni::Module::Base

    include Arachni::Module::Utilities

    EVENT_ATTRS = [
        'onload',
        'onunload',
        'onblur',
        'onchange',
        'onfocus',
        'onreset',
        'onselect',
        'onsubmit',
        'onabort',
        'onkeydown',
        'onkeypress',
        'onkeyup',
        'onclick',
        'ondblclick',
        'onmousedown',
        'onmousemove',
        'onmouseout',
        'onmouseover',
        'onmouseup',
        'src' # not an event but it fits the module structure
    ]

    def initialize( page )
        super( page )
    end

    def prepare( )
        @_injection_strs = [
            ";arachni_xss_in_element_event=" + seed + '//',
            "\";arachni_xss_in_element_event=" + seed + '//',
            "';arachni_xss_in_element_event=" + seed + '//',
        ]

        @_opts = {
            :format => [ Format::APPEND ],
        }
    end

    def run( )
        @_injection_strs.each {
            |str|
            audit( str, @_opts ) {
                |res, opts|
                log( opts, res ) if !( opts[:id] = _check( res, opts[:injected] ) ).empty?
            }
        }
    end

    def _check( res, injected_str )
        return [] if !res.body || !res.body.substring?( injected_str )

        doc = Nokogiri::HTML( res.body )
        EVENT_ATTRS.each {
            |attr|
            doc.xpath("//*[@#{attr}]").each {
                |elem|
                if elem.attributes[attr].to_s.substring?( injected_str )
                    return elem.to_s
                end
            }
        }

        return []
    end

    def self.info
        {
            :name           => 'XSS in HTML element event attribute',
            :description    => %q{Cross-Site Scripting in event tag of HTML element.},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE,
                Issue::Element::HEADER
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1.1',
            :references     => {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Cross-Site Scripting in event tag of HTML element.},
                :description => %q{Unvalidated user input is being embedded inside an HMTL event element such as "onmouseover".
                    This makes Cross-Site Scripting attacks much easier to mount since the user input
                    lands in code waiting to be executed.},
                :tags        => [ 'xss', 'event', 'injection', 'regexp', 'dom', 'attribute' ],
                :cwe         => '79',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '9.0',
                :remedy_guidance    => 'User inputs must be validated and filtered
                    before being included in executable code or not be included at all.',
                :remedy_code => '',
            }

        }
    end

end
end
end
