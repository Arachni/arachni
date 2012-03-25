=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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

module Arachni
module Modules

#
# XSS in HTML script tag. <br/>
# It injects strings and checks if they appear inside HTML 'script' tags.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.1.2
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
#
class XSSScriptTag < Arachni::Module::Base

    include Arachni::Module::Utilities

    def prepare
        @_injection_strs = [
            "arachni_xss_in_script_tag_" + seed + "",
            "\"arachni_xss_in_script_tag_" + seed + "\"",
            "'arachni_xss_in_script_tag_" + seed + "'"
        ]

        @_opts = {
            :format => [ Format::APPEND ],
        }
    end

    def run
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
                Issue::Element::HEADER
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1.2',
            :references     => {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Cross-Site Scripting in HTML "script" tag.},
                :description => %q{Unvalidated user input is being embedded inside a <script> element.
                    This makes Cross-Site Scripting attacks much easier to mount since user input lands inside
                    a trusted script.},
                :tags        => [ 'xss', 'script', 'tag', 'regexp', 'dom', 'attribute', 'injection' ],
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
