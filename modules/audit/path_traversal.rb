=begin
  $Id: xss.rb 371 2010-08-18 10:18:09Z zapotek $

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
# Path Traversal audit module.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: $Rev: 371 $
#
# @see http://cwe.mitre.org/data/definitions/22.html    
# @see http://www.owasp.org/index.php/Path_Traversal
#
class PathTraversal < Arachni::Module::Base

    include Arachni::Module::Registrar
    include Arachni::UI::Output

    def initialize( page )
        super( page )

        @results    = []
    end
    
    def prepare( )
        @__trv =  '../../../../../../../../../../../../etc/passwd'
        @__regexp = /\w+:.+:[0-9]+:[0-9]+:.+:[0-9a-zA-Z\/]+/ix
    end

    def run( )

        audit_forms( @__trv ) {
            |url, res, var|
            __log_results( Vulnerability::Element::FORM, var, res, url )
        }
        
        audit_links( @__trv ) {
            |url, res, var|
            __log_results( Vulnerability::Element::LINK, var, res, url )
        }
                
        audit_cookies( @__trv ) {
            |url, res, var|
            __log_results( Vulnerability::Element::COOKIE, var, res, url )
        }
        
        # register our results with the system
        register_results( @results )
    end

    
    def self.info
        {
            'Name'           => 'PathTraversal',
            'Description'    => %q{Path Traversal module.},
            'Elements'       => [ 
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE
            ],
            'Author'         => 'zapotek',
            'Version'        => '$Rev: 371 $',
            'References'     => {
                'OWASP' => 'http://www.owasp.org/index.php/Path_Traversal',
            },
            'Targets'        => { 'Generic' => 'all' },
                
            'Vulnerability'   => {
                'Name'        => %q{Path Traversal},
                'Description' => %q{Improper limitation of a pathname to a restricted directory.},
                'CWE'         => '79',
                'Severity'    => Vulnerability::Severity::HIGH,
                'CVSSV2'       => '9.0',
                'Remedy_Guidance'    => '',
                'Remedy_Code' => '',
            }

        }
    end
    
    def __log_results( where, var, res, url )

        if ( ( match = res.body.scan( @__regexp )[0] ) &&
               match.size > 0 )
            
            # append the result to the results hash
            @results << Vulnerability.new( {
                    'var'          => var,
                    'url'          => url,
                    'injected'     => @__trv,
                    'id'           => 'n/a',
                    'regexp'       => @__regexp.to_s,
                    'regexp_match' => match,
                    'elem'         => where,
                    'response'     => res.body,
                    'headers'      => {
                        'request'    => get_request_headers( ),
                        'response'   => get_response_headers( res ),    
                   }

                }.merge( self.class.info )
            )
                
            # inform the user that we have a match
            print_ok( self.class.info['Name'] +
                " in: #{where} var #{var}:\t" + url )
            
            # give the user some more info if he wants 
            print_verbose( "Injected str:\t" + @__trv )    
            print_verbose( "Matched regex:\t" + @__regexp.to_s )
            print_verbose( '---------' ) if only_positives?
    
        end
        
    end


end
end
end
end
