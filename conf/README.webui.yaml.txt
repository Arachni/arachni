The webui.yaml file holds configuration options for the Arachni WebUI *only*.
It currently contains only SSL options in the form of:
-------------------
ssl:
    server:
        enable:
        key:
        cert:
        ca:
    client:
        enable:
        key:
        cert:
        ca:
-------------------

Options under "server" refer to the WebUI HTTP server.
Options under "client" refer to the XMLRPC clients controlled by the WebUI
and used to communicate with the Dispatcher and the servers in its pool.

key: private key
cert: certificate
ca: CA certificate

All the options must be paths to ".pem" files and the keys should *NOT* be encrypted.
If you use encrypted keys you will cripple the system.

You can use the same "server" certificates and key when you start up the Dispatcher and the same
"client" certificates and key to authenticate your web browser to the WebUI server.

In essence, all Arachni servers can share the same credentials and the same goes for all clients.
This does not represent best practice key management though, which is the reason for the in-existence of
a global configuration file.

You may want to create different keys and certificates (signed by the same CA) for each component but you are not forced to.

You can set the "enable" options to "true" and leave the rest empty to use encryption without authentication.
In this case all Arachni servers will generate their own certificate/key pairs and peer verification will be disabled.

In order for client SSL to work the Dispatcher will need to be setup accordingly.
Run "arachni_xmlrpcd -h" to see the Dispatcher's relevant SSL options.


Finally, please pay close attention and do not alter to the indentation and formatting of the configuration file.

