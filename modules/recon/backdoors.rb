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
# Looks for common backdoors on the server.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
#
class Backdoors < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )
    end

    def prepare
        # to keep track of the requests and not repeat them
        @@__audited ||= Set.new

        # our results array
        @results = []

        @@__filenames ||=[]
        return if !@@__filenames.empty?

        read_file( 'filenames.txt' ) {
            |file|
            @@__filenames << file
        }
    end

    def run( )

        path = get_path( @page.url )
        return if @@__audited.include?( path )

        print_status( "Scanning..." )
        @@__filenames.each {
            |file|

            url  = path + file

            print_status( "Checking for #{url}" )

            req  = @http.get( url, :train => true )

            req.on_complete {
                |res|
                print_status( "Analyzing #{res.effective_url}" )
                __log_results( res, file )
            }
        }

        @@__audited << path
    end


    def self.info
        {
            :name           => 'Backdoors',
            :description    => %q{Tries to find common backdoors on the server.},
            :elements       => [ ],
            :author         => 'zapotek',
            :version        => '0.1',
            :references     => {},
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{A backdoor file exists on the server.},
                :description => %q{},
                :cwe         => '',
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

end
end
end
