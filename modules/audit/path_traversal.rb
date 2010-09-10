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
# Path Traversal audit module.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
#
# @see http://cwe.mitre.org/data/definitions/22.html    
# @see http://www.owasp.org/index.php/Path_Traversal
# @see http://projects.webappsec.org/Path-Traversal
#
class PathTraversal < Arachni::Module::Base

    include Arachni::Module::Registrar

    def initialize( page )
        super( page )

        @results    = []
    end
    
    def prepare( )
        @__trv =  '../../../../../../../../../../../../../../../../'
        @__ext = [
            "",
            "\0.htm",
            "\0.html",
            "\0.asp",
            "\0.aspx",
            "\0.php",
            "\0.txt",
            "\0.gif",
            "\0.jpg",
            "\0.jpeg",
            "\0.png",
            "\0.css"
        ]
        
        @__params = [
            {
                'value'  => 'etc/passwd',
                'regexp' => /\w+:.+:[0-9]+:[0-9]+:.+:[0-9a-zA-Z\/]+/i
            },
            {
                'value'  => 'boot.ini',
                'regexp' => /\[boot loader\](.*)\[operating systems\]/i
            }
          
        ]
        
        @__opts = {
            :format => [ Format::STRAIGHT ],
            :elements => [ Element::LINK, Element::FORM,
                           Element::COOKIE, Element::HEADER ]
        }

    end

    def run( )

        @__params.each {
            |param|
            
            @__opts[:regexp] = param['regexp']
            @__ext.each {
                |ext|
                
                injection_str = @__trv + param['value'] + ext
                
                audit( injection_str, @__opts ).each {
                  |res|
                  @results << Vulnerability.new( res.merge( self.class.info ) )
                }
            }
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
            'Version'        => '0.2',
            'References'     => {
                'OWASP' => 'http://www.owasp.org/index.php/Path_Traversal',
                'WASC'  => 'http://projects.webappsec.org/Path-Traversal'
            },
            'Targets'        => { 'Generic' => 'all' },
                
            'Vulnerability'   => {
                'Name'        => %q{Path Traversal},
                'Description' => %q{Improper limitation of a pathname to a restricted directory.},
                'CWE'         => '22',
                'Severity'    => Vulnerability::Severity::MEDIUM,
                'CVSSV2'       => '4.3',
                'Remedy_Guidance'    => '',
                'Remedy_Code' => '',
            }

        }
    end
    
    def __log_results( where, var, res, injection_str, regexp )

        if ( ( match = res.body.scan( regexp )[0] ) && match.size > 0 )
            
            injection_str = URI.escape( injection_str ) 
            
            url = res.effective_url
            # append the result to the results hash
            @results << Vulnerability.new( {
                    'var'          => var,
                    'url'          => url,
                    'injected'     => injection_str,
                    'id'           => 'n/a',
                    'regexp'       => regexp.to_s,
                    'regexp_match' => match,
                    'elem'         => where,
                    'response'     => res.body,
                    'headers'      => {
                        'request'    => res.request.headers,
                        'response'   => res.headers,    
                   }

                }.merge( self.class.info )
            )
                
            # inform the user that we have a match
            print_ok( "In #{where} var '#{var}' ( #{url} )" )
            
            # give the user some more info if he wants 
            print_verbose( "Injected str:\t" + injection_str )    
            print_verbose( "Matched regex:\t" + regexp.to_s )
            print_verbose( '---------' ) if only_positives?
    
        end
        
    end


end
end
end
end
