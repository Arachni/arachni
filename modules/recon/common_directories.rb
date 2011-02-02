=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'digest/sha1'

module Arachni

module Modules

#
# Common directories discovery module.
#
# Looks for common, possibly sensitive, directories on the server.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.4
#
# @see http://cwe.mitre.org/data/definitions/538.html
#
#
class CommonDirectories < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )
    end

    def prepare
        # to keep track of the requests and not repeat them
        @@__audited ||= Set.new

        # our results array
        @results = []

        @@__directories ||=[]
        return if !@@__directories.empty?

        read_file( 'directories.txt' ) {
            |file|
            @@__directories << file
        }
    end

    def run( )

        path = get_path( @page.url )
        return if @@__audited.include?( path )

        print_status( "Scanning..." )

        @@__directories.each {
            |dirname|

            url  = path + dirname + '/'
            print_status( "Checking for #{url}" )

            req  = @http.get( url, :train => true )

            req.on_complete {
                |res|
                print_status( "Analyzing #{res.effective_url}" )
                __log_results( res, dirname )
            }
        }

        @@__audited << path
    end

    def self.info
        {
            :name           => 'CommonDirectories',
            :description    => %q{Tries to find common directories on the server.},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1.4',
            :references     => {},
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{A common directory exists on the server.},
                :description => %q{},
                :tags        => [ 'path', 'directory', 'common' ],
                :cwe         => '538',
                :severity    => Issue::Severity::MEDIUM,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

    #
    # Adds an issue to the @results array<br/>
    # and outputs an "OK" message with the dirname and its url.
    #
    # @param  [Net::HTTPResponse]  res   the HTTP response
    # @param  [String]  dirname   the discovered dirname
    # @param  [String]  url   the url of the discovered file
    #
    def __log_results( res, dirname )

        return if( res.code != 200 || @http.custom_404?( res ) )

        url = res.effective_url
        # append the result to the results array
        @results << Issue.new( {
            :var          => 'n/a',
            :url          => url,
            :injected     => dirname,
            :id           => dirname,
            :regexp       => 'n/a',
            :regexp_match => 'n/a',
            :elem         => Issue::Element::PATH,
            :response     => res.body,
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
            }
        }.merge( self.class.info ) )

        # inform the user that we have a match
        print_ok( "Found #{dirname} at " + url )

        # register our results with the system
        register_results( @results )

    end

end
end
end
