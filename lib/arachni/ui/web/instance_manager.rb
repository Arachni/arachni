=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

require Arachni::Options.instance.dir['lib'] + 'rpc/client/instance'
require Arachni::Options.instance.dir['lib'] + 'ui/web/utilities'
require Arachni::Options.instance.dir['lib'] + 'rpc/client/instance'

module Arachni
module UI
module Web

#
# Provides methods for instance management.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.1
#
class InstanceManager

    include Utilities

    def initialize( opts, settings )
        @opts     = opts
        @settings = settings
    end

    #
    # Provides an easy way to connect to an instance
    #
    # @param    [String]   url
    # @param    [Hash]     session  session of the current user (optional)
    # @param    [String]   token    authentication token (optional)
    #
    # @return   [Arachni::RPC::Client::Instance]
    #
    def connect( url, session = nil, token = nil )
        #
        # Sync up the session authentication tokens with the ones in the
        # class variables.
        #
        # This will allow users to still connect to instances even if they
        # shutdown the WebUI or remove their cookies.
        #
        @@tokens ||= {}
        session['tokens'] ||= {} if session
        @@tokens[url] = token if token

        session['tokens'].merge!( @@tokens ) if session
        @@tokens.merge!( session['tokens'] ) if session
        session['tokens'].merge!( @@tokens ) if session

        tmp_token = session ? session['tokens'][url] : @@tokens[url]

        Arachni::RPC::Client::Instance.new( @opts, url, tmp_token )
    end

end
end
end
end
