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
# Appends common backup extesions to the filename of the page under audit<br/>
# and checks for its existence. 
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

        @__backup_ext_file = 'extensions.txt'
        
        # our results hash
        @results = []
    end

    def run( )

        # ugly crap but it works, as far as I can tell...
        path     = Module::Utilities.get_path( @page.url )
        regex    = path + '(.*)'
        
        filename = @page.url.match( Regexp.new( regex ) )
        filename = filename[1].gsub( /\?(.*)/, '' ) 
        
        if( filename.empty? )
            print_debug( self.class.info['Name'] + ' is backing out. ' + 
              'Can\'t extract filename from url: ' + @page.url )
            return
        end
        
        get_data_file( @__backup_ext_file ) {
            |ext|
            
            #
            # Test for the existance of the file + extension.
            #
            # We're not worrying about its contents, the Trainer will
            # analyze it and if it's HTML it'll extract any new attack vectors.
            #
            
            file = ext % filename # Example: index.php.bak
            url  = path + file
            res  = @http.get( url )

            __log_results( res, file, url ) if( res.code == "200" )
            
            file = ext % filename.gsub( /\.(.*)/, '' ) # Example: index.bak
            url  = path + file
            res  = @http.get( url )
            
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
                'Name'        => %q{A backup file exists on the server.},
                'Description' => %q{},
                'CWE'         => '530',
                'Severity'    => Vulnerability::Severity::HIGH,
                'CVSSV2'       => '',
                'Remedy_Guidance'    => '',
                'Remedy_Code' => '',
            }

        }
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
