=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

def reset_options
    opts = Arachni::Options.instance
    opts.reset
    opts.rpc.server_address = '127.0.0.1'
    opts.browser_cluster.pool_size = 1

    opts.paths.plugins        = fixtures_path + 'plugins/'
    opts.paths.checks         = fixtures_path + 'checks/'
    opts.paths.fingerprinters = fixtures_path + 'fingerprinters/'
    opts.paths.logs           = spec_path + 'support/logs/'

    opts
end

def reset_all
    Arachni::UI::Output.reset_output_options
    Arachni::Framework.reset
    reset_options
    Arachni::HTTP::Client.reset
end

def killall
    instance_killall
    dispatcher_killall
    web_server_killall
    process_killall
    # process_kill_reactor
end
