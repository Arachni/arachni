=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

module Arachni

module Modules

#
# HTTP Response Splitting recon module.
#
# It audits links, forms and cookies.
#
# @see http://www.owasp.org/index.php/HTTP_Response_Splitting
#
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: $Rev$
#
class ResponseSplitting < Arachni::Module::Base

    # register us with the system
    include Arachni::Module::Registrar
    # get output interface
    include Arachni::UI::Output

    def initialize( page_data, structure )
        super( page_data, structure )

        # initialize the header
        @__header = ''
        
        # initialize the hash that's hold the results
        @results = []
    end

    def prepare( )
        
        # the header to inject...
        # what we will check for in the response header
        # is the existence of the "x-crlf-safe" field.
        # if we find it it means that the site is vulnerable
        @__header = "\r\nContent-Type: text/html\r\nHTTP/1.1" +
            " 200 OK\r\nContent-Type: text/html\r\nX-CRLF-Safe: No\r\n\r\n"
    end
    
    def run( )
        
        # URL encode the header to be injected
        enc_header = URI.encode( @__header )
        
        # try to inject the header via the forms of the page
        # and pass a block that will check for a positive result
        audit_forms( enc_header ) {
            |var, res|
            __log_results( 'form', var, res )
        }
        
        # try to inject the header via the link variables
        # and pass a block that will check for a positive result        
        audit_links( enc_header ) {
            |var, res|
            __log_results( 'link', var, res )
        }
        
        # try to inject the header via cookies
        # and pass a block that will check for a positive result
        audit_cookies( enc_header ) {
            |var, res|
            __log_results( 'cookie', var, res )
        }
        
        #register our results with the system
        register_results( @results )
    end

    
    def self.info
        {
            'Name'           => 'ResponseSplitting',
            'Description'    => %q{Response Splitting recon module.
                Tries to inject some data into the webapp and figure out
                if any of them end up in the response header. 
            },
            'Methods'        => ['get', 'post', 'cookie'],
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
            'References'     => {
                 'SecuriTeam'    => 'http://www.securiteam.com/securityreviews/5WP0E2KFGK.html',
                 'OWASP'         => 'http://www.owasp.org/index.php/HTTP_Response_Splitting'
            },
            'Targets'        => { 'Generic' => 'all' },
                
            'Vulnerability'   => {
                'Description' => %q{The web application includes user input
                     in the response HTTP header.},
                'CWE'         => '20',
                'Severity'    => 'Medium',
                'CVSSV2'       => '5.0',
                'Remedy_Guidance'    => '',
                'Remedy_Code' => '',
            }

        }
    end
    
    private
    
    def __log_results( where, var, res )
        if res.get_fields( 'x-crlf-safe' )
        
            @results << Vulnerability.new( {
                    'var'          => var,
                    'url'          => page_data['url']['href'],
                    'injected'     => @__header,
                    'id'           => 'x-crlf-safe',
                    'regexp'       => nil,
                    'regexp_match' => nil,
                    'elem'         => where,
                    'response'     => res.body,
                    'headers'      => {
                        'request'    => get_request_headers( ),
                        'response'   => get_response_headers( res ),    
                    }
                }.merge( self.class.info )
            )

            print_ok( self.class.info['Name'] + " in: #{where} var #{var}" +
                        '::' + page_data['url']['href'] )
        end
    end

end
end
end
