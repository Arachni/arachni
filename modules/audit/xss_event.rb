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
# XSS in HTML element event attribute. <br/>
# It injects a string and checks if it appears inside an event attribute of any HTML tag.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
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
        'onmouseup'
    ]

    def initialize( page )
        super( page )
    end

    def prepare( )
        @_injection_strs = [
            # "; arachni_xss_in_element_event=" + seed + '//',
            "\"; arachni_xss_in_element_event=" + seed + '//',
            "'; arachni_xss_in_element_event=" + seed + '//',
        ]

        @_opts = {
            :format => [ Format::APPEND ],
        }
    end

    def run( )
        @_injection_strs.each {
            |str|
            audit( str, @_opts ) {
                |res, altered, opts|
                _log( res, altered, opts )
            }
        }
    end

    def _check( res, injected_str )
        doc = Nokogiri::HTML( res.body )
        EVENT_ATTRS.each {
            |attr|
            doc.xpath("//*[@#{attr}]").each {
                |elem|
                return elem.to_s if injected_str && elem.to_s.match( injected_str )
            }
        }

        return []
    end

    def _log( res, altered, opts )
        return if !res.body

        begin
            # see if we managed to inject javascript into any event attribute
            if !( html_elem = _check( res, opts[:combo][altered] ) ).empty?

                elem = opts[:element]
                url  = res.effective_url
                print_ok( "In #{elem} var '#{altered}' " + ' ( ' + url + ' )' )

                injected = opts[:combo][altered] ? opts[:combo][altered] : '<n/a>'
                print_verbose( "Injected string:\t" + injected )
                print_verbose( "Verified string:\t" + html_elem.to_s )
                print_debug( 'Request ID: ' + res.request.id.to_s )
                print_verbose( '---------' ) if only_positives?


                res = {
                    :var          => altered,
                    :url          => url,
                    :injected     => injected,
                    :id           => html_elem.to_s,
                    :regexp       => html_elem.to_s,
                    :regexp_match => html_elem.to_s,
                    :response     => res.body,
                    :elem         => elem,
                    :method       => res.request.method.to_s,
                    :opts         => opts.dup,
                    :verification => 'true',
                    :headers      => {
                        :request    => res.request.headers,
                        :response   => res.headers,
                    }
                }

                Arachni::Module::Manager.register_results(
                    [ Vulnerability.new( res.merge( self.class.info ) ) ]
                )

            end
        end
    end

    def self.info
        {
            :name           => 'XSS in HTML element event attribute',
            :description    => %q{Cross-Site Scripting in event tag of HTML element.},
            :elements       => [
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE,
            ],
            :author         => 'zapotek',
            :version        => '0.1',
            :references     => {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{Cross-Site Scripting in event tag of HTML element.},
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
