=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Loads and runs an external Ruby script under the scope of a plugin,
# used for debugging and general hackery.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1.2
class Arachni::Plugins::Script < Arachni::Plugin::Base

    def run
        if defined?( Arachni::RPC::Server::Framework ) &&
            framework.is_a?( Arachni::RPC::Server::Framework )
            print_error 'Cannot be executed while running as an RPC server.'
            return
        end

        print_status "Loading #{options[:path]}"
        eval IO.read( options[:path] )
        print_status 'Done!'
    end

    def self.info
        {
            name:        'Script',
            description: %q{
Loads and runs an external Ruby script under the scope of a plugin, used for
debugging and general hackery.

_Will not work over RPC._
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.2',
            options:     [
                Options::Path.new( :path,
                    required:    true,
                    description: 'Path to the script.'
                )
            ]
        }
    end

end
