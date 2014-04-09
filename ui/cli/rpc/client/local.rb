=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'local/option_parser'
require_relative 'instance'

module Arachni

require Options.paths.lib + 'processes'

module UI::CLI
module RPC
module Client

# Spawns and controls an {RPC::Server::Instance} directly to avoid having to
# use a {RPC::Server::Dispatcher} to take advantage of RPC-only features like
# multi-Instance scans.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Local

    def initialize
        parser = Local::OptionParser.new
        parser.authorized_by
        parser.scope
        parser.audit
        parser.http
        parser.checks
        parser.plugins
        parser.platforms
        parser.session
        parser.profiles
        parser.browser_cluster
        parser.distribution
        parser.parse

        options = parser.options

        # Tells all Instances which are going to be spawned to ignore interrupt
        # signals.
        options.datastore.do_not_trap = true

        # Spawns an Instance and configures it to listen on a UNIX-domain socket.
        instance = Processes::Instances.spawn(
            socket: "/tmp/arachni-#{Arachni::Utilities.available_port}"
        )

        # Let the Instance UI manage the Instance from now on.
        Instance.new( options, instance ).run

        # Make sure the Instance processes are killed.
        Processes::Instances.killall
    end

end

end
end
end
end
