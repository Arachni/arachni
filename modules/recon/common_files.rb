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
# Backup file discovery module.
#
# Looks for sensitive common files on the server. 
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: $Rev: 385 $
#
#
class CommonFiles < Arachni::Module::Base

    # register us with the system
    include Arachni::Module::Registrar
    
    # get output interface
    include Arachni::UI::Output

    def initialize( page )
        super( page )

        @__common_files = 'filenames.txt'
        
        # our results hash
        @results = []
    end

    def run( )

        # ugly crap but it works, as far as I can tell...
        path = Module::Utilities.get_path( @page.url )
        
        get_data_file( @__common_files ) {
            |file|
            
            #
            # Test for the existance of the file
            #
            # We're not worrying about its contents, the Trainer will
            # analyze it and if it's HTML it'll extract any new attack vectors.
            #
            
            url  = path + file
            res  = @http.get( url )

            __log_results( res, file, url ) if( res.code == "200" )
        }

        
        # register our results with the system
        register_results( @results )
    end

    
    def self.info
        {
            'Name'           => 'CommonFiles',
            'Description'    => %q{Tries to find common sensitive files on the server.},
            'Elements'       => [ ],
            'Author'         => 'zapotek',
            'Version'        => '$Rev: 385 $',
            'References'     => {},
            'Targets'        => { 'Generic' => 'all' },
                
            'Vulnerability'   => {
                'Name'        => %q{A common sensitive file exists on the server.},
                'Description' => %q{},
                'CWE'         => '530',
                'Severity'    => Vulnerability::Severity::HIGH,
                'CVSSV2'       => '',
                'Remedy_Guidance'    => '',
                'Remedy_Code' => '',
            }

        }
    end
    
    def __get_path( url )
      
        splits = []
        tmp = ''
        
        url.each_char {
            |c|
            if( c != '/' )
                tmp += c
            else
                splits << tmp
                tmp = ''
            end
        }
        
        if( !tmp =~ /\./ )
          splits << tmp
        end
        
        return splits.join( "/" ) + '/'
    end
    
    def __log_results( res, filename, url )
        
        # append the result to the results hash
        @results << Vulnerability.new( {
            'var'          => 'n/a',
            'url'          => url,
            'injected'     => filename,
            'id'           => filename,
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
            " named #{filename} at\t" + url )
    end

end
end
end
end
