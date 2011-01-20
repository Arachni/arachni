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
# XSS in HTML script tag. <br/>
# It injects strings and checks if they appear inside HTML 'script' tags.
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
class XSSScriptTag < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )
    end

    def prepare( )
        @_injection_strs = [
            "arachni_xss_in_script_tag_" + seed + "",
            "\"arachni_xss_in_script_tag_" + seed + "\"",
            "'arachni_xss_in_script_tag_" + seed + "'"
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
        # if we have no body or it doesn't contain the injected string under any
        # context there's no point in parsing the HMTL to verify the vulnerability
        return if !res.body || !res.body.substring?( opts[:injected] )

        begin
            doc = Nokogiri::HTML( res.body )

            # see if we managed to inject a working HTML attribute to any
            # elements
            if !(html_elem = doc.xpath("//script")).empty? &&
                html_elem.to_s.substring?( opts[:injected] )
                opts[:match] = html_elem.to_s
                log( opts, res )
            end
        end
    end

    def self.info
        {
            :name           => 'XSS in HTML "script" tag',
            :description    => %q{Injects strings and checks if they appear inside HTML 'script' tags.},
            :elements       => [
                Issue::Element::FORM,
                Issue::Element::LINK,
                Issue::Element::COOKIE,
            ],
            :author         => 'zapotek',
            :version        => '0.1.1',
            :references     => {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Cross-Site Scripting in HTML "script" tag.},
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
