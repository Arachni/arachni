require Options.paths.root + 'ui/cli/output'
require Options.paths.lib  + 'rest/server'

Rest::Server.run!(
    port:     Options.rpc.server_port,
    bind:     Options.rpc.server_address,

    username: Options.datastore['username'],
    password: Options.datastore['password'],

    ssl_ca:          Options.rpc.ssl_ca,
    ssl_key:         Options.rpc.server_ssl_private_key,
    ssl_certificate: Options.rpc.server_ssl_certificate
)
