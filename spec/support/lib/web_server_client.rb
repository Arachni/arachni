=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'arachni/rpc'

# @note Needs `ENV['WEB_SERVER_DISPATCHER']` in the format of `host:port`.
#
# {WebServerManager}-API-compatible client for the {WebServerDispatcher}.
#
# Delegates test webserver creation to the machine running {WebServerDispatcher},
# for hosts that lack support for fast servers (like Windows, which can't run
# Thin, Puma etc.).
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class WebServerClient < Arachni::RPC::Proxy
    include Singleton

    def initialize( options = {} )
        @host, port = ENV['WEB_SERVER_DISPATCHER'].split( ':' )

        Arachni::Reactor.global.run_in_thread if !Arachni::Reactor.global.running?

        client = Arachni::RPC::Client.new( host: @host, port: port )
        super client, 'server'
    end

    def protocol_for( name )
        name.to_s.include?( 'https' ) ? 'https' : 'http'
    end

    def address_for( name )
        @host
    end

    def up?( name )
        Typhoeus.get(
            url_for( name, false ),
            ssl_verifypeer: false,
            ssl_verifyhost: 0,
            forbid_reuse:   true
        ).code != 0
    end

end
