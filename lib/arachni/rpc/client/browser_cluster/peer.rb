=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

require Options.paths.lib + 'rpc/client/base'

module RPC
class Client

class BrowserCluster

# {BrowserCluster::Peer} client.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Peer < RemoteObjectMapper

    def initialize( socket, token = nil )
        super( RPC::Client::Base.new( Options.instance, socket, token ), 'browser' )
    end

end

end
end
end
end
