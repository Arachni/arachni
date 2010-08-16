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

#
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

        # code to inject
        @__backup_files = ['index.php.bak']
        
        # our results hash
        @results = []
    end

    def run( )
        
        path = File.dirname( URI.parse( @page.url ).path ) + '/'
        
        # iterate through the injection codes
        @__backup_files.each {
            |file|
            res = @http.get( path + file )
            # puts res.body
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
                'CWE'         => '',
                'Severity'    => Vulnerability::Severity::HIGH,
                'CVSSV2'       => '',
                'Remedy_Guidance'    => '',
                'Remedy_Code' => '',
            }

        }
    end

end
end
end
