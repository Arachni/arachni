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

require_relative 'instance'

module Arachni

require Options.dir['lib'] + 'processes'

module UI
class CLI

module RPC

#
# Spawns and controls an {RPC::Server::Instance} directly to avoid having to
# use a {RPC::Server::Dispatcher} to take advantage of RPC-only features
# like multi-Instance scans.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Local
    include Arachni::UI::Output
    include CLI::Utilities

    def initialize( opts = Arachni::Options.instance )
        @opts = opts

        # If the user needs help, output it and exit.
        if opts.help
            print_banner
            usage
            exit 0
        end

        # Tells all Instances which are going to be spawned to ignore interrupt
        # signals.
        @opts.datastore[:do_not_trap] = true

        # Spawns an Instance and configures it to listen on a UNIX-domain socket.
        instance = Processes::Instances.spawn( socket: "/tmp/arachni-#{available_port}" )

        # Let the Instance UI manage the Instance from now on.
        Instance.new( @opts, instance ).run

        # Make sure the Instance processes are killed.
        Processes::Instances.killall
    end

    # Outputs help/usage information.
    def usage
        super

        print_line <<USAGE
    Distribution -----------------

    --spawns=<integer>          How many slaves to spawn for a high-performance mult-Instance scan.

USAGE
    end

end

end
end
end
end
