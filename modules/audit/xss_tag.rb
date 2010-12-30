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
# XSS in HTML tag. <br/>
# It injects a string and checks if it appears inside a any HTML tags.
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
class XSSImageSource < Arachni::Module::Base

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
                |res, altered, opts|
                _log( res, altered, opts )
            }
        }
    end

    def _log( res, altered, opts )
        return if !res.body

        begin
            doc = Nokogiri::HTML( res.body )

            # see if we managed to inject a working HTML attribute to any
            # elements
            if !(elem = doc.xpath("//*[@#{TAG_NAME}]")).empty?

                res = {
                    :var          => altered,
                    :url          => res.effective_url,
                    :injected     => opts[:combo][altered] ? opts[:combo][altered] : '<n/a>',
                    :id           => elem.to_s,
                    :regexp       => elem.to_s,
                    :regexp_match => elem.to_s,
                    :response     => res.body,
                    :elem         => opts[:element],
                    :method       => res.request.method.to_s,
                    :opts         => opts.dup,
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
            :name           => 'XSS in HTML tag',
            :description    => %q{Cross-Site Scripting in HTML tag.},
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
                :name        => %q{Cross-Site Scripting in HTML tag.},
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
