=begin
  $Id: backup_files.rb 385 2010-08-22 22:21:46Z zapotek $

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

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
# @version: $Rev: 385 $
#
# @see http://cwe.mitre.org/data/definitions/538.html
#
#
class CommonDirectories < Arachni::Module::Base

    # register us with the system
    include Arachni::Module::Registrar
    
    # get output interface
    include Arachni::UI::Output
    include Arachni::Module::Utilities
    
    def initialize( page )
        super( page )

        @__common_directories = 'directories.txt' 
        
        @results = []
    end

    def run( )

        # ugly crap but it works, as far as I can tell...
        path = Module::Utilities.get_path( @page.url )
        
        get_data_file( @__common_directories ) {
            |dirname|
            
            url  = path + dirname + '/'
            res  = @http.get( url )

            __log_results( res, dirname, url ) if( res.code == "200" )
        }

        
        # register our results with the system
        register_results( @results )
    end

    
    def self.info
        {
            'Name'           => 'CommonDirectories',
            'Description'    => %q{Tries to find common directories on the server.},
            'Elements'       => [ ],
            'Author'         => 'zapotek',
            'Version'        => '$Rev: 385 $',
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
    
    def __log_results( res, dirname, url )
        
        # append the result to the results hash
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
                'request'    => 'n/a',
                'response'   => 'n/a',    
            }
        }.merge( self.class.info ) )
                
        # inform the user that we have a match
        print_ok( self.class.info['Name'] +
            " named #{dirname} at\t" + url )
    end

end
end
end
end
