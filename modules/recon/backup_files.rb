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
module Recon
#
# Backup file discovery module.
#
# Just a placeholder for now...
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: $Rev$
#
#
class BackupFiles < Arachni::Module::Base

    # register us with the system
    include Arachni::Module::Registrar
    # get output interface
    include Arachni::UI::Output

    def initialize( page )
        super( page )

        # just this for now...
        @__backup_files = ['index.php.bak']
        
        # our results hash
        @results = []
    end

    def run( )
        
        # get the path to the folder of the page we're auditing
        path = URI.parse( @page.url ).path
        
        # ruby's split doesn't work as it should, we'll use our own
        # with a twist
        path = __get_path( path ).join( "/" ) + '/'
        
        # iterate through the injection codes
        @__backup_files.each {
            |file|
            
            #
            # Test for the existance of the file.
            #
            # We're not worrying about its contents, the Trainer will
            # analyze it and if it's HTML it'll extract any new attack vectors.
            #
            url = path + file
            res = @http.get( url )

            __log_results( res, file, url ) if( res.code == "200" )
        }
        
        # register our results with the system
        register_results( @results )
    end

    
    def self.info
        {
            'Name'           => 'BackupFiles',
            'Description'    => %q{Tries to find sensitive backup files.},
            'Elements'       => [ ],
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
            'References'     => {},
            'Targets'        => { 'Generic' => 'all' },
                
            'Vulnerability'   => {
                'Name'        => %q{A sensitive backup file exists on the server.},
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
        
        return splits
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
