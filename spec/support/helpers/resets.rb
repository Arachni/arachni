=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
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
