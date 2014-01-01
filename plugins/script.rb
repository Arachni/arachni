=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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

#
# Loads and runs an external Ruby script under the scope of a plugin,
# used for debugging and general hackery.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class Arachni::Plugins::Script < Arachni::Plugin::Base

    def run
        if Arachni::Options.rpc_address
            print_error 'Cannot be executed while running as an RPC server.'
            return
        end

        print_status "Loading #{options['path']}"
        eval( IO.read( options['path'] ) )
        print_status 'Done!'
    end

    def self.info
        {
            :name           => 'Script',
            :description    => %q{Loads and runs an external Ruby script under the scope of a plugin,
                used for debugging and general hackery.

                Will not work over RPC.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.1',
            :options        => [
                Options::Path.new( 'path', [ true, 'Path to the script.' ] )
            ]
        }
    end

end
