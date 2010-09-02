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
# Blind SQL injection audit module
# 
# It uses a SQL timing attacks.<br/>
# This is going to be greatly improved in the future<br/>
# to support other DBs as well. 
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: $Rev$
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://capec.mitre.org/data/definitions/7.html
# @see http://www.owasp.org/index.php/Blind_SQL_Injection
#
class BlindSQLInjection < Arachni::Module::Base

    # register us with the system
    include Arachni::Module::Registrar
    # get output module
    include Arachni::UI::Output

    BASELINE_NUM  = 5
    
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
        # we'll try some timing attacks on the remote DB
        #
        @__injection_strs = [
            # MySQL
            ' AND BENCHMARK(5000000,ENCODE(1,1)) --',
            '\' AND BENCHMARK(5000000,ENCODE(1,1)) --',
            '" AND BENCHMARK(5000000,ENCODE(1,1)) --',
            # MSSQL
            ';waitfor delay \'0:0:5\'--',
            '\';waitfor delay \'0:0:5\'--',
            '";waitfor delay \'0:0:5\'--',
            # PostgreSQL
            ';SELECT pg_sleep(5);--',
            '\';SELECT pg_sleep(5);--',
            '\";SELECT pg_sleep(5);--'
        ]
        
    end
    
    def run( )

        print_status( self.class.info['Name'] + 
          " is establishing a timing attack baseline." )

        deltas = 0.0
        # establish a baseline
        BASELINE_NUM.times {
            |i|
            res    =  @http.get( @page.url )
            deltas += res.time
            
            print_debug( self.class.info['Name'] +
              " --> Request #{i+1}/#{BASELINE_NUM} took #{res.time.to_s}s." )
        }
        
        # get the baseline plus 5 seconds for the query execution.
        # of course this is just a guestimate...
        baseline = deltas / BASELINE_NUM + 5.0
        
        print_status( self.class.info['Name'] +
        " established a maximum baseline limit of #{baseline}s." )
        
        # iterate through the regular expression strings
        @__injection_strs.each {
            |str|
            
            audit_forms( str ) {
                |url, res, var|
                
                if( res.time > baseline )
                    __log_results( Vulnerability::Element::FORM, var, res, str, url )
                end
            }
            
            audit_links( str ) {
                |url, res, var|
                
                if( res.time > baseline )
                    __log_results( Vulnerability::Element::LINK, var, res, str, url )
                end
            }

            audit_cookies( str ) {
                |url, res, var|

                if( res.time > baseline )
                    __log_results( Vulnerability::Element::COOKIE, var, res, str, url )
                end
            }
        }
        
        # register our results with the framework
        register_results( @results )
    end

    
    def self.info
        {
            'Name'           => 'BlindSQLInjection',
            'Description'    => %q{SQL injection recon module},
            'Elements'       => [
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE
            ],
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
            'References'     => {
                'OWASP'      => 'http://www.owasp.org/index.php/Blind_SQL_Injection',
                'MITRE - CAPEC' => 'http://capec.mitre.org/data/definitions/7.html'
            },
            'Targets'        => { 'Generic' => 'all' },
                
            'Vulnerability'   => {
                'Name'        => %q{Blind SQL Injection},
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
    
    def __log_results( where, var, res, injection_str, url )
        
        # append the result to the results hash
        @results << Vulnerability.new( {
                'var'          => var,
                'url'          => url,
                'injected'     => injection_str,
                'id'           => 'n/a',
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
            
        # inform the user that we have a match
        print_ok( self.class.info['Name'] +
            " in: #{where} var #{var}:\t" + url )
                
        # give the user some more info if he wants 
        print_verbose( "Injected str:\t" + injection_str )    
        print_verbose( '---------' ) if only_positives?
    
    end

end
end
end
end
