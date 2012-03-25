=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni
module Modules

#
# Looks for common backdoors on the server.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.2.1
#
#
class Backdoors < Arachni::Module::Base

    include Arachni::Module::Utilities

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

    def run

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
            :version        => '0.2.1',
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
