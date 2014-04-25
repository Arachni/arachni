require_relative 'base'
require Options.paths.root + 'ui/cli/output'
require Options.paths.lib  + 'rpc/server/dispatcher'

::EM.run do
    RPC::Server::Dispatcher.new
end
