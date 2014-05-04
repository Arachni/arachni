require Options.paths.root + 'ui/cli/output'
require Options.paths.lib  + 'rpc/server/dispatcher'

Reactor.global.run do
    RPC::Server::Dispatcher.new
end
