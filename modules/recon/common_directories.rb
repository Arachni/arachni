=begin
                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'digest/sha1'

module Arachni

module Modules
module Recon
  
#
# Common directories discovery module.
#
# Looks for common, possibly sensitive, directories on the server.
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.2
#
# @see http://cwe.mitre.org/data/definitions/538.html
#
#
class CommonDirectories < Arachni::Module::Base

    # register us with the system
    include Arachni::Module::Registrar
    
    def initialize( page )
        super( page )

        @__common_directories = 'directories.txt'
        
        # to keep track of the requests and not repeat them
        @@__audited ||= []
        @results   = []
    end

    def run( )

        print_status( "Scanning..." )

        path = Module::Utilities.get_path( @page.url )

        get_data_file( @__common_directories ) {
            |dirname|
            
            url  = path + dirname + '/'
            
            next if @@__audited.include?( url )
            print_debug( "Checking for #{url}" )
            
            req  = @http.get( url )
            @@__audited << url

            req.on_complete {
                |res|
                print_debug( "Analyzing #{res.effective_url}" )
                __log_results( res, dirname )
            }
        }

        @http.run
        
        # register our results with the system
        register_results( @results )
    end

    def self.info
        {
            'Name'           => 'CommonDirectories',
            'Description'    => %q{Tries to find common directories on the server.},
            'Elements'       => [ ],
            'Author'         => 'zapotek',
            'Version'        => '0.1.2',
            'References'     => {},
            'Targets'        => { 'Generic' => 'all' },
                
            'Vulnerability'   => {
                'Name'        => %q{A common directory exists on the server.},
                'Description' => %q{},
                'CWE'         => '538',
                'Severity'    => Vulnerability::Severity::MEDIUM,
                'CVSSV2'       => '',
                'Remedy_Guidance'    => '',
                'Remedy_Code' => '',
            }

        }
    end
    
    #
    # Adds a vulnerability to the @results array<br/>
    # and outputs an "OK" message with the dirname and its url.
    #
    # @param  [Net::HTTPResponse]  res   the HTTP response
    # @param  [String]  dirname   the discovered dirname 
    # @param  [String]  url   the url of the discovered file
    #
    def __log_results( res, dirname )
        
        return if( res.code != 200 || @http.custom_404?( res.body ) )
        
        url = res.effective_url
        # append the result to the results array
        @results << Vulnerability.new( {
            'var'          => 'n/a',
            'url'          => url,
            'injected'     => dirname,
            'id'           => dirname,
            'regexp'       => 'n/a',
            'regexp_match' => 'n/a',
            'elem'         => Vulnerability::Element::LINK,
            'response'     => res.body,
            'headers'      => {
                'request'    => res.request.headers,
                'response'   => res.headers,    
            }
        }.merge( self.class.info ) )
                
        # inform the user that we have a match
        print_ok( "Found #{dirname} at " + url )
    end

end
end
end
end
