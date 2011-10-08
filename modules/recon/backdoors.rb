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
# @version: 0.2
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
            log_remote_file_if_exists( url ) {
                |res|
                # inform the user
                print_ok( "Found #{file} at " + res.effective_url )
            }
        }

        @@__audited << path
    end


    def self.info
        {
            :name           => 'Backdoors',
            :description    => %q{Tries to find common backdoors on the server.},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.2',
            :references     => {},
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{A backdoor file exists on the server.},
                :description => %q{ The server response indicates that a file matching
                    the name of a common backdoor is publicly accessible.
                    This indicates that the server has been compromised and can
                    (to some extent) be remotely controled by unauthorised users.},
                :tags        => [ 'path', 'backdoor', 'file', 'discovery' ],
                :cwe         => '',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

end
end
end
