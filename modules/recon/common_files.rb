=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules

#
# Backup file discovery module.
#
# Looks for sensitive common files on the server.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.2
#
#
class CommonFiles < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )

        @__common_files = 'filenames.txt'

        # to keep track of the requests and not repeat them
        @@__audited ||= []

        # our results array
        @results = []
    end

    def run( )

        print_status( "Scanning..." )

        path = get_path( @page.url )

        read_file( @__common_files ) {
            |file|

            #
            # Test for the existance of the file
            #
            # We're not worrying about its contents, the Trainer will
            # analyze it and if it's HTML it'll extract any new attack vectors.
            #

            url  = path + file

            next if @@__audited.include?( url )
            print_status( "Checking for #{url}" )

            req  = @http.get( url, :train => true )
            @@__audited << url

            req.on_complete {
                |res|
                print_status( "Analyzing #{res.effective_url}" )
                __log_results( res, file )
            }
        }

    end


    def self.info
        {
            :name           => 'CommonFiles',
            :description    => %q{Tries to find common sensitive files on the server.},
            :elements       => [ ],
            :author         => 'zapotek',
            :version        => '0.1.2',
            :references     => {},
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{A common sensitive file exists on the server.},
                :description => %q{},
                :cwe         => '530',
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
    # @param  [String]  url   the url of the discovered file
    #
    def __log_results( res, filename )

        return if( res.code != 200 || @http.custom_404?( res.body ) )

        url = res.effective_url
        # append the result to the results array
        @results << Vulnerability.new( {
            :var          => 'n/a',
            :url          => url,
            :injected     => filename,
            :id           => filename,
            :regexp       => 'n/a',
            :regexp_match => 'n/a',
            :elem         => Vulnerability::Element::LINK,
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

end
end
end
