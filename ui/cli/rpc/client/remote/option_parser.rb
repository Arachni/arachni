=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative '../../../framework/option_parser'

module Arachni
module UI::CLI

module RPC
module Client
class Remote

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class OptionParser < UI::CLI::Framework::OptionParser

    def distribution
        separator 'Distribution'

        on( '--dispatcher-url HOST:PORT', 'Dispatcher server to use.' ) do |url|
            options.dispatcher.url = url
        end

        on( '--spawns SPAWNS', Integer,
               'How many slaves to spawn for a high-performance mult-Instance scan.',
               '(When no grid mode has been specified, all slaves will all be from the same Dispatcher machine.',
               'When a grid-mode has been specified, this option will be treated as a possible maximum and',
               'not a hard value.)'
        ) do |spawns|
            options.spawns = spawns
        end

        on( "--grid-mode #{OptionGroups::Dispatcher::GRID_MODES.join(',')}",
            OptionGroups::Dispatcher::GRID_MODES,
            'Sets the Grid mode of operation for this scan.',
            'Valid modes are:',
            '  * balance -- Slaves will be provided by the least burdened Grid Dispatchers.',
            '  * aggregate -- In addition to balancing, slaves will all be from Dispatchers',
            '    with unique bandwidth Pipe-IDs to result in application-level line-aggregation.'
        ) do |mode|
            options.dispatcher.grid_mode = mode
        end

        on( '--grid', "Shorthand for '--grid-mode=balance'." ) do
            options.dispatcher.grid = true
        end
    end

    def ssl
        separator ''
        separator 'SSL'

        on( '--ssl-ca FILE',
            'Location of the CA certificate (.pem).'
        ) do |file|
            options.rpc.ssl_ca = file
        end

        on( '--ssl-private-key FILE',
            'Location of the client SSL private key (.pem).'
        ) do |file|
            options.rpc.client_ssl_private_key = file
        end

        on( '--ssl-certificate FILE',
            'Location of the client SSL certificate (.pem).'
        ) do |file|
            options.rpc.client_ssl_certificate = file
        end
    end

    def validate
        validate_dispatcher
        super
    end

    def validate_dispatcher
        # Check for missing Dispatcher
        if !options.dispatcher.url
            print_error "Missing '--dispatcher-url' option."
            exit 1
        end
    end

    def banner
        "Usage: #{$0} [options] --dispatcher-url HOST:PORT URL"
    end

end

end
end
end
end
end
