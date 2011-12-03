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
# Looks for common hidden files on the server, based on wordlists generated from 
# robots.txt files from the Response Analysis and Further Testing Tool (RAFT) project.
# 
# More information about the RAFT wordlists:
#   http://code.google.com/p/raft/
#
# The RAFT program is released under the GPL v3.0 License.
#
# @author: Herman Stevens
#                                      <herman.stevens@gmail.com>
#                                      http://blog.astyran.sg
#
# @version: 0.1
#
# @see http://cwe.mitre.org/data/definitions/538.html
#
class RaftFiles < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )
    end

	def prepare
        # to keep track of the requests and not repeat them
        @@__audited ||= Set.new

        @@__filenames ||=[]
        return if !@@__filenames.empty?

        read_file( 'raft-large-files.txt' ) {
            |file|
            @@__filenames << file unless file.include?( '?' )
        }

	end

    def run( )
        path = get_path( @page.url )
        return if @@__audited.include?( path )

        print_status( "Scanning RAFT Files..." )

        @@__filenames.each {
            |file|

            url  = path + file
            print_status( "Checking for #{url}" )

            log_remote_file_if_exists( url ) {
                |res|
                print_ok( "Found #{file} at " + res.effective_url )
            }
        }

        @@__audited << path
    end


    def self.info
        {
            :name           => 'RAFT Files',
            :description    => %q{Finds files, based on wordlists created from robots.txt.

                The wordlist utilized by this module will be vast and will add a considerable
                amount of time to the overall scan time.},
            :elements       => [ ],
            :author         => 'Herman Stevens <herman.stevens@gmail.com> ',
            :version        => '0.1',
            :references     => {
                'Response Analysis and Further Testing Tool' =>
                    'http://code.google.com/p/raft/',
                'OWASP Testing Guide' =>
                    'https://www.owasp.org/index.php/Testing_for_Old,_Backup_and_Unreferenced_Files_(OWASP-CM-006)'
        	},
            :targets        => { 'Generic' => 'all' },
            :issue          => {
                :name        => %q{A RAFT file was detected.},
                :description => %q{},
                :tags        => [ 'raft', 'path', 'file', 'discovery' ],
                :cwe         => '538',
                :severity    => Issue::Severity::INFORMATIONAL,
                :cvssv2      => '',
                :remedy_guidance    => 'Review these resources manually. Check if unauthorized interfaces are exposed,
                    or confidential information.',
                :remedy_code => '',
            }

        }
    end

end
end
end
