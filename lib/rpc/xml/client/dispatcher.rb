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
# @version: 0.1
#
class Dispatcher

    def initialize( opts, url )
        @opts = opts

        # connect to the dispatcher
        @dispatcher = ::XMLRPC::Client.new2( url )

        # there'll be a HELL of lot of output so things might get..laggy.
        # a big timeout is required to avoid Timeout exceptions...
        @dispatcher.timeout = 9999999


        if @opts.ssl_pkey || @opts.ssl_pkey
            @dispatcher.instance_variable_get( :@http ).
                instance_variable_set( :@ssl_context, prep_ssl_context( ) )
        else
            @dispatcher.instance_variable_get( :@http ).
                instance_variable_set( :@verify_mode, OpenSSL::SSL::VERIFY_NONE )
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

    def prep_ssl_context

        pkey = ::OpenSSL::PKey::RSA.new( File.read( @opts.ssl_pkey ) )         if @opts.ssl_pkey
        cert = ::OpenSSL::X509::Certificate.new( File.read( @opts.ssl_cert ) ) if @opts.ssl_cert


        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.ca_file = @opts.ssl_ca
        ssl_context.verify_depth = 5
        ssl_context.verify_mode = ::OpenSSL::SSL::VERIFY_PEER |
            ::OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
        ssl_context.key  = pkey
        ssl_context.cert = cert
        return ssl_context
    end

end

end
end
end
end
