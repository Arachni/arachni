=begin
  $Id$

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
# HTTP Response Splitting recon module.
#
# It audits links, forms and cookies.
#
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: $Rev$
#
# @see http://cwe.mitre.org/data/definitions/20.html    
# @see http://www.owasp.org/index.php/HTTP_Response_Splitting
# @see http://www.securiteam.com/securityreviews/5WP0E2KFGK.html    
#
class ResponseSplitting < Arachni::Module::Base

    # register us with the system
    include Arachni::Module::Registrar

    def initialize( page )
        super( page )

        # initialize the header
        @__header = ''
        
        # initialize the array that will hold the results
        @results = []
    end

    def prepare( )
        
        # the header to inject...
        # what we will check for in the response header
        # is the existence of the "x-crlf-safe" field.
        # if we find it it means that the attack was succesful
        # thus site is vulnerable.
        @__header = "\r\nX-CRLF-Safe: no"
    end
    
    def run( )
        
        # try to inject the header via the forms of the page
        # and pass a block that will check for a positive result
        audit_forms( @__header ) {
            |url, res, var|
            __log_results( Vulnerability::Element::FORM, var, res, url )
        }
        
        # try to inject the header via the link variables
        # and pass a block that will check for a positive result        
        audit_links( @__header ) {
            |url, res, var|
            __log_results( Vulnerability::Element::LINK, var, res, url )
        }
        
        # try to inject the header via cookies
        # and pass a block that will check for a positive result
        audit_cookies( @__header ) {
            |url, res, var|
            __log_results( Vulnerability::Element::COOKIE, var, res, url )
        }
        
        # register our results with the system
        register_results( @results )
    end

    
    def self.info
        {
            'Name'           => 'ResponseSplitting',
            'Description'    => %q{Response Splitting recon module.
                Tries to inject some data into the webapp and figure out
                if any of them end up in the response header. 
            },
            'Elements'       => [
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE
            ],
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
            'References'     => {
                 'SecuriTeam'    => 'http://www.securiteam.com/securityreviews/5WP0E2KFGK.html',
                 'OWASP'         => 'http://www.owasp.org/index.php/HTTP_Response_Splitting'
            },
            'Targets'        => { 'Generic' => 'all' },
                
            'Vulnerability'   => {
                'Name'        => %q{Response splitting},
                'Description' => %q{The web application includes user input
                     in the response HTTP header.},
                'CWE'         => '20',
                'Severity'    => Vulnerability::Severity::MEDIUM,
                'CVSSV2'       => '5.0',
                'Remedy_Guidance'    => '',
                'Remedy_Code' => '',
            }

        }
    end
    
    private
    
    def __log_results( where, var, res, url )
        if res.get_fields( 'X-CRLF-Safe' )
        
            @results << Vulnerability.new( {
                    'var'          => var,
                    'url'          => url,
                    'injected'     => URI.encode( @__header ),
                    'id'           => 'x-crlf-safe',
                    'regexp'       => 'n/a',
                    'regexp_match' => 'n/a',
                    'elem'         => where,
                    'response'     => res.body,
                    'headers'      => {
                        'request'    => get_request_headers( ),
                        'response'   => get_response_headers( res ),    
                    }
                }.merge( self.class.info )
            )

            print_ok( "In #{where} var '#{var}' ( #{url} )" )
        end
    end

end
end
end
end
