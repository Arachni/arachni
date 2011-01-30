=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'xmlrpc/client'
require 'openssl'

module Arachni
module RPC
module XML
module Client

#
# XMLRPC Dispatcher client
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class Dispatcher

    def initialize( opts, url )
        @opts = opts

        # connect to the dispatcher
        @dispatcher = ::XMLRPC::Client.new2( url )

        # there'll be a HELL of lot of output so things might get..laggy.
        # a big timeout is required to avoid Timeout exceptions...
        @dispatcher.timeout = 9999999


        if @opts.ssl_ca
            @dispatcher.instance_variable_get( :@http ).instance_variable_set( :@ca_file, @opts.ssl_ca )
            @dispatcher.instance_variable_get( :@http ).instance_variable_set( :@verify_mode, OpenSSL::SSL::VERIFY_PEER )
        else
            @dispatcher.instance_variable_get( :@http ).instance_variable_set( :@verify_mode, OpenSSL::SSL::VERIFY_NONE )
        end

    end

    private
    #
    # Used to provide the illusion of locality for remote methods
    #
    def method_missing( sym, *args, &block )
        call = "dispatcher.#{sym.to_s}"
        @dispatcher.call( call, *args )
    end

end

end
end
end
end
