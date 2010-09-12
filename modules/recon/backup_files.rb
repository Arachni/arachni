=begin
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
# @version: 0.1.3
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

        filename = File.basename( URI( @page.url ).path )
        path     = Module::Utilities.get_path( @page.url )
        
        if( !filename  )
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
            next if !( req1 = __request_once( url ) )

            
            req1.on_complete {
                |res|
                __log_results( res, file )
            }
            
            file = ext % filename.gsub( /\.(.*)/, '' ) # Example: index.bak
            url  = path + file
            next if !( req2 = __request_once( url ) )
            
            req2.on_complete {
                |res|
                __log_results( res, file )
            }
        }

    end

    
    def self.info
        {
            :name           => 'BackupFiles',
            :description    => %q{Tries to find sensitive backup files.},
            :elements       => [ ],
            :author         => 'zapotek',
            :version        => '0.1.3',
            :references     => {},
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{A backup file exists on the server.},
                :description => %q{},
                :cew         => '530',
                :severity    => Vulnerability::Severity::HIGH,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end
    
    #
    # Adds a vulnerability to the @results array<br/>
    # and outputs an "OK" message with the filename and its url.
    #
    # @param  [Net::HTTPResponse]  res   the HTTP response
    # @param  [String]  filename   the discovered filename 
    #
    def __log_results( res, filename )
        
        return if( res.code != 200 || @http.custom_404?( res.body ) )
          
        url = res.effective_url
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
                'request'    => res.request.headers,
                'response'   => res.headers,    
            }
        }.merge( self.class.info ) )

        # register our results with the system
        register_results( @results )
                
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
    def __request_once( url )
      
        return false if @@__audited.include?( url )
        
        print_debug( "Checking for #{url}" )
        
        req  = @http.get( url )
        @@__audited << url
        
        return req
    end

end
end
end
end
