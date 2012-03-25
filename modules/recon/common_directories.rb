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
# Common directories discovery module.
#
# Looks for common, possibly sensitive, directories on the server.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.2.1
#
# @see http://cwe.mitre.org/data/definitions/538.html
#
#
class CommonDirectories < Arachni::Module::Base

    include Arachni::Module::Utilities

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

    def run
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
            :version        => '0.2.1',
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
