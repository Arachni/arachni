=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
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
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Local

    def initialize
        parser = Local::OptionParser.new
        parser.authorized_by
        parser.scope
        parser.audit
        parser.input
        parser.http
        parser.checks
        parser.plugins
        parser.platforms
        parser.session
        parser.profiles
        parser.browser_cluster
        parser.distribution
        parser.report
        parser.timeout
        parser.parse

        options = parser.options

        # Tells all Instances which are going to be spawned to ignore interrupt
        # signals.
        options.datastore.do_not_trap = true

        instance = Processes::Instances.spawn

        # Let the Instance UI manage the Instance from now on.
        Instance.new( options, instance, parser.get_timeout ).run

        # Make sure the Instance processes are killed.
        Processes::Instances.kill( instance.url )
    end

end

end
end
end
end
