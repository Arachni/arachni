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
module Plugins

#
# Loads and runs an external Ruby script under the scope of a plugin,
# used for debugging and general hackery.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.1
#
class Script < Arachni::Plugin::Base

    def run
        if Arachni.constants.include?( :RPC )
            print_error 'Cannot be executed while running as an RPC server.'
            return
        end

        path = Dir.getwd + '/' + @options['path']
        print_status "Loading #{path}"
        eval( IO.read( path ) )
        print_status 'Done!'
    end

    def self.info
        {
            :name           => 'Script',
            :description    => %q{Loads and runs an external Ruby script under the scope of a plugin,
                used for debugging and general hackery.

                Will not work over RPC.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                Arachni::OptPath.new( 'path', [ true, 'Path to the script.' ] )
            ]
        }
    end

end

end
end
