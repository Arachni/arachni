=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    Please see the LICENSE file at the root directory of the project.
=end

require 'terminal-table/import'
require_relative 'dispatcher/option_parser'

module Arachni

require Options.paths.lib + 'rpc/server/dispatcher'
require_relative '../../utilities'

module UI::CLI
module RPC
module Server

# @author Tasos "Zapotek" Laskos<tasos.laskos@gmail.com>
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
