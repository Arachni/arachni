The webui.yaml file holds configuration options for the Arachni WebUI and any service that may be started or accessed by it.
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
Options under "client" refer to the RPC clients controlled by the WebUI
and used to communicate with Dispatchers and Instances in its pool.

key: private key
cert: certificate
ca: CA certificate

All the options must be paths to ".pem" files and the keys should *NOT* be encrypted.
If you use encrypted keys you will cripple the system.

It is very important that you set 'enable' to true when you configure any parameters.