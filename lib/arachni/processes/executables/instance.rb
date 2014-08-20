require Options.paths.root + 'ui/cli/output'
require Options.paths.lib  + 'rpc/server/instance'

if (socket = $options[:socket])
    Options.rpc.server_address          = nil
    Options.dispatcher.external_address = nil
    Options.rpc.server_port             = nil
    Options.rpc.server_socket           = socket
elsif (port = $options[:port])
    Options.rpc.server_port = port
end

RPC::Server::Instance.new( Options, $options[:token] )
