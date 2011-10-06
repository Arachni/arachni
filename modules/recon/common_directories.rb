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
# @version: 0.2
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

            log_remote_directory_if_exists( url ) {
                |res|
                print_ok( "Found #{dirname} at " + res.effective_url )
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
            :version        => '0.2',
            :references     => {},
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{A common directory exists on the server.},
                :description => %q{},
                :tags        => [ 'path', 'directory', 'common', 'discovery' ],
                :cwe         => '538',
                :severity    => Issue::Severity::MEDIUM,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

end
end
end
