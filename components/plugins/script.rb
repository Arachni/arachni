=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Loads and runs an external Ruby script under the scope of a plugin,
# used for debugging and general hackery.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class Arachni::Plugins::Script < Arachni::Plugin::Base

    def run
        if Arachni::Options.rpc_server_address
            print_error 'Cannot be executed while running as an RPC server.'
            return
        end

        print_status "Loading #{options['path']}"
        eval( IO.read( options['path'] ) )
        print_status 'Done!'
    end

    def self.info
        {
            :name           => 'Script',
            :description    => %q{Loads and runs an external Ruby script under the scope of a plugin,
                used for debugging and general hackery.

                Will not work over RPC.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.1',
            :options        => [
                Options::Path.new( 'path', [ true, 'Path to the script.' ] )
            ]
        }
    end

end
