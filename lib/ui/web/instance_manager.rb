=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require Arachni::Options.instance.dir['lib'] + 'rpc/xml/client/instance'
require Arachni::Options.instance.dir['lib'] + 'ui/web/utilities'

module Arachni
module UI
module Web

#
# Provides methods for instance management.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
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
    # @return   [Arachni::RPC::XML::Client::Instance]
    #
    def connect( url, session = nil, token = nil )
        url = 'https://' + url if !url.include?( 'https' )

        begin

            #
            # Sync up the session authentication tokens with the ones in the
            # class variables.
            #
            # This will allow users to still connect to instances even if they
            # shutdown the WebUI or removed their cookies.
            #

            @@tokens ||= {}
            session['tokens'] ||= {} if session
            @@tokens[url] = token if token

            session['tokens'].merge!( @@tokens ) if session
            @@tokens.merge!( session['tokens'] ) if session
            session['tokens'].merge!( @@tokens ) if session

            tmp_token = session ? session['tokens'][url] : @@tokens[url]

            return Arachni::RPC::XML::Client::Instance.new( @opts, url, tmp_token )
        rescue Exception => e
            raise "Instance at #{url} has shutdown."
        end
    end

end
end
end
end
