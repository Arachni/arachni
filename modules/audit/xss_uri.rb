=begin
                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules
module Audit

#
# XSS in URI audit module.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
# @see http://cwe.mitre.org/data/definitions/79.html    
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
#
class XSSURI < Arachni::Module::Base

    include Arachni::Module::Registrar

    def initialize( page )
        super( page )

        @results    = []
    end
    
    def prepare( )
        @__injection_strs = [
            '/>\'><ScRiPt>a=/RANDOMIZE/</ScRiPt>',
            '/>"><ScRiPt>a=/RANDOMIZE/</ScRiPt>',
            '/>><ScRiPt>a=/RANDOMIZE/</ScRiPt>'
        ]
    end

    def run( )

        @__injection_strs.each {
            |str|
            
            url  = @page.url + str
            req  = @http.get( url )
            
            req.on_complete {
                |res|
                __log_results( res, str )
            }
        }

        @http.run
        # register our results with the system
        register_results( @results )
    end

    
    def self.info
        {
            'Name'           => 'XSSURI',
            'Description'    => %q{Cross-Site Scripting module for path injection},
            'Elements'       => [ ],
            'Author'         => 'zapotek',
            'Version'        => '0.1',
            'References'     => {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            'Targets'        => { 'Generic' => 'all' },
                
            'Vulnerability'   => {
                'Name'        => %q{Cross-Site Scripting (XSS) in URI},
                'Description' => %q{Client-side code, like JavaScript, can
                    be injected into the web application.},
                'CWE'         => '79',
                'Severity'    => Vulnerability::Severity::HIGH,
                'CVSSV2'       => '9.0',
                'Remedy_Guidance'    => '',
                'Remedy_Code' => '',
            }

        }
    end
    
    def __log_results( res, id )

        regexp = Regexp.new( Regexp.escape( id ) )
        
        if ( id && res.body.scan( regexp )[0] == id ) ||
           ( !id && res.body.scan( regexp )[0].size > 0 )
           
            url = res.effective_url
            # append the result to the results hash
            @results << Vulnerability.new( {
                'var'          => 'n/a',
                'url'          => url,
                'injected'     => id,
                'id'           => id,
                'regexp'       => regexp,
                'regexp_match' => id,
                'elem'         => Vulnerability::Element::LINK,
                'response'     => res.body,
                'headers'      => {
                    'request'    => res.request.headers,
                    'response'   => res.headers,    
                }
            }.merge( self.class.info ) )
                    
            # inform the user that we have a match
            print_ok( "In #{@page.url} at " + url )
                
        end
    end


end
end
end
end
