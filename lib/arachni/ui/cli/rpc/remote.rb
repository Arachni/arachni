=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require_relative 'instance'

module Arachni

require Options.dir['lib'] + 'rpc/client/dispatcher'
require Options.dir['lib'] + 'rpc/client/instance'

require Options.dir['lib'] + 'utilities'
require Options.dir['lib'] + 'ui/cli/utilities'

module UI
class CLI

module RPC

#
# Provides a command-line RPC client and uses a {RPC::Server::Dispatcher} to
# provide an {RPC::Server::Instance} in order to perform a scan.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Remote
    include Arachni::UI::Output
    include CLI::Utilities

    attr_reader :error_log_file

    def initialize( opts = Arachni::Options.instance )
        @opts = opts

        # If the user needs help, output it and exit.
        if opts.help
            print_banner
            usage
            exit 0
        end

        # Check for missing Dispatcher
        if !@opts.server
            print_banner
            print_error 'Missing server argument.'
            exit 1
        end

        begin
            dispatcher = Arachni::RPC::Client::Dispatcher.new( @opts, @opts.server )

            # Get a new instance and assign the url we're going to audit as the 'owner'.
            instance_info = dispatcher.dispatch( @opts.url )
        rescue Arachni::RPC::Exceptions::ConnectionError => e
            print_error "Could not connect to dispatcher at '#{@opts.server}'."
            print_debug "Error: #{e.to_s}."
            print_debug_backtrace e
            exit 1
        end

        begin
            # start the RPC client
            instance = Arachni::RPC::Client::Instance.new( @opts,
                                                           instance_info['url'],
                                                           instance_info['token'] )
        rescue Arachni::RPC::Exceptions::ConnectionError => e
            print_error 'Could not connect to instance.'
            print_debug "Error: #{e.to_s}."
            print_debug_backtrace e
            exit 1
        end

        # Let the Instance UI manage the Instance from now on.
        Instance.new( @opts, instance ).run
    end

    # Outputs help/usage information.
    def usage
        super '--server host:port'

        print_line <<USAGE
    Distribution -----------------

    --server=<address:port>     Dispatcher server to use.
                                  (Used to provide scanner Instances.)

    --spawns=<integer>          How many slaves to spawn for a high-performance mult-Instance scan.
                                  (When no grid mode has been specified, all slaves will all be from the same Dispatcher machine.
                                    When a grid-mode has been specified, this option will be treated as a possible maximum and
                                    not a hard value.)

    --grid-mode=<mode>          Sets the Grid mode of operation for this scan.
                                  Valid modes are:
                                    * balance -- Slaves will be provided by the least burdened Grid Dispatchers.
                                    * aggregate -- In addition to balancing, slaves will all be from Dispatchers
                                        with unique bandwidth Pipe-IDs to result in application-level line-aggregation.

    --grid                      Shorthand for '--grid-mode=balance'.


    SSL --------------------------
    (Do *not* use encrypted keys!)

    --ssl-pkey=<file>           Location of the SSL private key (.pem)
                                  (Used to verify the the client to the servers.)

    --ssl-cert=<file>           Location of the SSL certificate (.pem)
                                  (Used to verify the the client to the servers.)

    --ssl-ca=<file>             Location of the CA certificate (.pem)
                                  (Used to verify the servers to the client.)


USAGE
    end

end

end
end
end
end
