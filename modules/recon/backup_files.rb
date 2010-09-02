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
    
    def initialize( page )
        super( page )

        @__backup_ext_file = 'extensions.txt'
        
        # to keep track of the requests and not repeat them
        @@__audited ||= []
        
        # our results array
        @results = []
    end

    def run( )

        print_status( "Scanning..." )

        # ugly crap but it works, as far as I can tell...
        path     = Module::Utilities.get_path( @page.url )
        regex    = path + '(.*)'
        
        filename = @page.url.match( Regexp.new( regex ) )
        filename = filename[1].gsub( /\?(.*)/, '' ) 
        
        if( filename.empty? )
            print_debug( 'Backing out. ' + 
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
            next if !( res = __get_once( url ) )

            __log_results( res, file, url ) if( res.code == "200" )
            
            file = ext % filename.gsub( /\.(.*)/, '' ) # Example: index.bak
            url  = path + file
            res = __get_once( url )
            
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
    
    #
    # Adds a vulnerability to the @results array<br/>
    # and outputs an "OK" message with the filename and its url.
    #
    # @param  [Net::HTTPResponse]  res   the HTTP response
    # @param  [String]  filename   the discovered filename 
    # @param  [String]  url   the url of the discovered file
    #
    def __log_results( res, filename, url )
        
        # append the result to the results array
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
        print_ok( "Found #{filename} at " + url )
    end
    
    #
    # Gets a URL only once
    #
    # @param  [String]  url   the url to get
    #
    # @return  [FalseClass/HTTPResponse]   false if the url has been
    #                                          previously requested,<br/>
    #                                          the HTTPResponse otherwise
    #
    def __get_once( url )
      
        return false if @@__audited.include?( url )
        
        print_debug( "Checking for #{url}" )
        
        res  = @http.get( url )
        @@__audited << url
        
        return res
    end

end
end
end
end
