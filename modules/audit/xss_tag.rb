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
# XSS in HTML tag. <br/>
# It injects a string and checks if it appears inside any HTML tags.
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
class XSSHTMLTag < Arachni::Module::Base

    include Arachni::Module::Utilities

    TAG_NAME = 'arachni_xss_in_tag'

    def initialize( page )
        super( page )
    end

    def prepare( )
        @_injection_strs = [
            " #{TAG_NAME}=" + seed,
            "\" #{TAG_NAME}=\"" + seed,
            "' #{TAG_NAME}='" + seed,
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
                _log( res, opts )
            }
        }
    end

    def _log( res, opts )
        # if we have no body or it doesn't contain the TAG_NAME under any
        # context there's no point in parsing the HMTL to verify the vulnerability
        return if !res.body || !res.body.substring?( TAG_NAME )

        begin
            doc = Nokogiri::HTML( res.body )

            # see if we managed to inject a working HTML attribute to any
            # elements
            if !(html_elem = doc.xpath("//*[@#{TAG_NAME}]")).empty?
                opts[:match] = html_elem.to_s
                log( opts, res )
            end
        end
    end

    def self.info
        {
            :name           => 'XSS in HTML tag',
            :description    => %q{Cross-Site Scripting in HTML tag.},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE,
                Issue::Element::HEADER
            ],
            :author         => 'zapotek',
            :version        => '0.1.1',
            :references     => {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Cross-Site Scripting in HTML tag.},
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
