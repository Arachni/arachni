require Options.paths.root + 'ui/cli/output'
require Options.paths.lib  + 'rest/server'

Rest::Server.run!(
    port:     Arachni::Options.rpc.server_port,
    bind:     Arachni::Options.rpc.server_address,

    username: Arachni::Options.datastore['username'],
    password: Arachni::Options.datastore['password'],

    ssl_ca:          Arachni::Options.rpc.ssl_ca,
    ssl_key:         Arachni::Options.rpc.server_ssl_private_key,
    ssl_certificate: Arachni::Options.rpc.server_ssl_certificate
)
