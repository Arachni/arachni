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
# SQL Injection recon module.<br/>
# It audits links, forms and cookies.
#
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.4
#
# @see http://cwe.mitre.org/data/definitions/89.html    
# @see http://unixwiz.net/techtips/sql-injection.html
# @see http://en.wikipedia.org/wiki/SQL_injection
# @see http://www.securiteam.com/securityreviews/5DP0N1P76E.html
# @see http://www.owasp.org/index.php/SQL_Injection
#
class SQLInjection < Arachni::Module::Base

    # register us with the system
    include Arachni::Module::Registrar

    def initialize( page )
        super( page )

        # initialize variables 
        @__id = []
        @__injection_strs = []
        
        # initialize the results hash
        @results = []
    end

    def prepare( )
        
        #
        # it's better to save big arrays to a file
        # a big array is ugly, messy and can't be updated as easily
        #
        # but don't open the file yourself, use get_data_file( filename )
        # with a block and read each line
        #
        # keep your files under modules/<modtype>/<modname>/
        #
        @__regexp_ids_file = 'regexp_ids.txt'
        
        # prepare the strings that will hopefully cause the webapp
        # to output SQL error messages
        @__injection_strs = [
            '\'',
            '--',
            ';',
            '`'
        ]
        
    end
    
    def run( )
        
        # iterate through the regular expression strings
        @__injection_strs.each {
            |str|
            
            # send the bad characters in @__injection_strs via the page forms
            # and pass a block that will check for a positive result
            audit_forms( str ) {
                |res, var|
                __log_results( Vulnerability::Element::FORM, var, res, str )
            }
            
            # send the bad characters in @__injection_strs via link vars
            # and pass a block that will check for a positive result        
            audit_links( str ) {
                |res, var|
                __log_results( Vulnerability::Element::LINK, var, res, str )
            }
                    
            # send the bad characters in @__injection_strs via cookies
            # and pass a block that will check for a positive result
            audit_cookies( str ) {
                |res, var|
                __log_results( Vulnerability::Element::COOKIE, var, res, str )
            }
        }
        
        # register our results with the framework
        register_results( @results )
    end

    
    def self.info
        {
            'Name'           => 'SQLInjection',
            'Description'    => %q{SQL injection recon module},
            'Elements'       => [
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE
            ],
            'Author'         => 'zapotek',
            'Version'        => '0.1.4',
            'References'     => {
                'UnixWiz'    => 'http://unixwiz.net/techtips/sql-injection.html',
                'Wikipedia'  => 'http://en.wikipedia.org/wiki/SQL_injection',
                'SecuriTeam' => 'http://www.securiteam.com/securityreviews/5DP0N1P76E.html',
                'OWASP'      => 'http://www.owasp.org/index.php/SQL_Injection'
            },
            'Targets'        => { 'Generic' => 'all' },
                
            'Vulnerability'   => {
                'Name'        => %q{SQL Injection},
                'Description' => %q{SQL code can be injected into the web application.},
                'CWE'         => '89',
                'Severity'    => Vulnerability::Severity::HIGH,
                'CVSSV2'       => '9.0',
                'Remedy_Guidance'    => '',
                'Remedy_Code' => '',
            }

        }
    end
    
    private
    
    def __log_results( where, var, res, injection_str )
        
        url = res.effective_url
        # iterate through the regular expressions in @__regexp_ids_file
        # and try to match them with the body of the HTTP response
        get_data_file( @__regexp_ids_file ) {
            |id|
            
            # strip whitespace from the regexp
            id = id.strip
            
            # just to make sure...
            if id.size == 0 then next end
            
            # create a regular expression from the regexp strings
            id_regex = Regexp.new( id )
            
            # try to match them with the body of the HTTP response,
            # if it matches we have a positive result
            if ( ( match = res.body.scan( id_regex )[0] ) &&
                 res.body.scan( id_regex )[0].size > 0 )
                
                # append the result to the results array
                @results << Vulnerability.new( {
                        'var'          => var,
                        'url'          => url,
                        'injected'     => injection_str,
                        'id'           => id,
                        'regexp'       => id_regex.to_s,
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
                print_ok( "In #{where} var #{var} ( #{url} )" )
                
                # give the user some more info if he wants 
                print_verbose( "Injected str:\t" + injection_str )    
                print_verbose( "ID str:\t\t" + id )
                print_verbose( "Matched regex:\t" + id_regex.to_s )
                print_verbose( '---------' ) if only_positives?
        
                # since a regexp tested positive for SQL injection
                # we don't need to test for the rest
                return true
            end
            
        }
        
    end

end
end
end
end
