=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules

#
# Backup file discovery module.
#
# Appends common backup extesions to the filename of the page under audit<br/>
# and checks for its existence.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.5
#
#
class BackupFiles < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )
    end

    def prepare
        # to keep track of the requests and not repeat them
        @@__audited ||= []

        # our results array
        @results = []

        @@__extensions ||=[]
        return if !@@__extensions.empty?

        read_file( 'extensions.txt' ) {
            |file|
            @@__extensions << file
        }
    end

    def run( )

        filename = File.basename( URI( @page.url ).path )
        path     = get_path( @page.url )

        return if @@__audited.include?( path )

        print_status( "Scanning..." )

        if( !filename  )
            print_info( 'Backing out. ' +
              'Can\'t extract filename from url: ' + @page.url )
            return
        end

        @@__extensions.each {
            |ext|

            #
            # Test for the existance of the file + extension.
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

        @@__audited << path
    end


    def self.info
        {
            :name           => 'BackupFiles',
            :description    => %q{Tries to find sensitive backup files.},
            :elements       => [ ],
            :author         => 'zapotek',
            :version        => '0.1.5',
            :references     => {},
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{A backup file exists on the server.},
                :description => %q{},
                :cew         => '530',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

    #
    # Adds an issue to the @results array<br/>
    # and outputs an "OK" message with the filename and its url.
    #
    # @param  [Net::HTTPResponse]  res   the HTTP response
    # @param  [String]  filename   the discovered filename
    #
    def __log_results( res, filename )

        # some webapps disregard the extension and load the page anyway
        # which will lead to false positives, take care of that.
        return if res.body == @page.html

        return if( res.code != 200 || @http.custom_404?( res ) )

        url = res.effective_url
        # append the result to the results array
        @results << Issue.new( {
            :var          => 'n/a',
            :url          => url,
            :injected     => filename,
            :id           => filename,
            :regexp       => 'n/a',
            :regexp_match => 'n/a',
            :elem         => Issue::Element::PATH,
            :response     => res.body,
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
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

        print_status( "Checking for #{url}" )

        # force the Trainer to analyze it and if it's HTML it'll extract any new attack vectors.
        req  = @http.get( url, :train => true )

        return req
    end

end
end
end
