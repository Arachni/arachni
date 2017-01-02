=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'terminal-table/import'
require_relative 'dispatcher/option_parser'

module Arachni

require Options.paths.lib + 'rpc/server/dispatcher'
require_relative '../../utilities'

module UI::CLI
module RPC
module Server

# @author Tasos "Zapotek" Laskos<tasos.laskos@arachni-scanner.com>
class Dispatcher

    def initialize
        OptionParser.new.parse

        Reactor.global.run do
            Arachni::RPC::Server::Dispatcher.new
        end
    end

end
end
end
end
end
