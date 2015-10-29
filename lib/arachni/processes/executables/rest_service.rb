require Options.paths.root + 'ui/cli/output'
require Options.paths.lib  + 'rest/server'

Rest::Server.run!(
    port:     Arachni::Options.rpc.server_port,
    bind:     Arachni::Options.rpc.server_address,
    username: Arachni::Options.datastore['username'],
    password: Arachni::Options.datastore['password']
)
