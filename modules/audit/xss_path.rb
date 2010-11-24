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
# XSS in path audit module.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.2
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
#
class XSSPath < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )

        @results    = []
    end

    def prepare( )
        @str = '/<arachni_xss_path_' + seed
        @__injection_strs = [
            @str,
            '?>"\'>' + @str,
            '?=>"\'>' + @str
        ]
    end

    def run( )

        path = get_path( @page.url )

        @__injection_strs.each {
            |str|

            url  = path + str
            req  = @http.get( url )

            req.on_complete {
                |res|
                __log_results( res, str )
            }
        }

    end


    def self.info
        {
            :name           => 'XSSPath',
            :description    => %q{Cross-Site Scripting module for path injection},
            :elements       => [ ],
            :author         => 'zapotek',
            :version        => '0.1.2',
            :references     => {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{Cross-Site Scripting (XSS) in path},
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

    def __log_results( res, id )

        if ( id && res.body.scan( Regexp.escape( id ) )[0] == id ) ||
           ( !id && res.body.scan( Regexp.escape( id ) )[0].size > 0 )

            url = res.effective_url
            # append the result to the results hash
            @results << Vulnerability.new( {
                :var          => 'n/a',
                :url          => url,
                :injected     => id,
                :id           => id,
                :regexp       => 'n/a',
                :regexp_match => 'n/a',
                :elem         => Vulnerability::Element::LINK,
                :response     => res.body,
                :headers      => {
                    :request    => res.request.headers,
                    :response   => res.headers,
                }
            }.merge( self.class.info ) )

            # inform the user that we have a match
            print_ok( "Match at #{url}" )
            print_verbose( "Inected string: #{id}" )

            # register our results with the system
            register_results( @results )
        end
    end


end
end
end
