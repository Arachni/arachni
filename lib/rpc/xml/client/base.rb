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
# Basic self-configuring XMLRPC client supporting cert-based SSL client/server authentication
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class Base

    #
    # Maps the methods of remote objects to local ones
    #
    class Mapper

        def initialize( server, remote )
            @server = server
            @remote = remote
        end

        private
        #
        # Used to provide the illusion of locality for remote methods
        #
        def method_missing( sym, *args, &block )
            call = "#{@remote}.#{sym.to_s}"
            @server.call( call, *args )
        end

    end

    def initialize( opts, url, token = nil )

        @opts = opts

        url        = URI( url )
        url.scheme = 'https'

        # start the XMLRPC client
        @server = ::XMLRPC::Client.new2( url.to_s )

        @server.cookie = 'token=' + token + ';' if token

        @server.timeout = 50


        if @opts.ssl_ca || @opts.ssl_pkey || @opts.ssl_cert

            pkey = ::OpenSSL::PKey::RSA.new( File.read( opts.ssl_pkey ) )         if @opts.ssl_pkey
            cert = ::OpenSSL::X509::Certificate.new( File.read( opts.ssl_cert ) ) if @opts.ssl_cert

            @server.instance_variable_get( :@http ).instance_variable_set( :@key, pkey )
            @server.instance_variable_get( :@http ).instance_variable_set( :@cert, cert )

            @server.instance_variable_get( :@http ).instance_variable_set( :@ca_file, @opts.ssl_ca )
            @server.instance_variable_get( :@http ).instance_variable_set( :@verify_mode,
                OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT )

        else
            @server.instance_variable_get( :@http ).instance_variable_set( :@verify_mode, OpenSSL::SSL::VERIFY_NONE )
        end

    end

    #
    # Used to make old school XMLRPC calls
    #
    def call( method, *args )
        tries = 0
        begin
            @server.call( method, *args )
        rescue Errno::EPIPE => e
            ap 'RETRYING: ' + tries.to_s
            ap e
            tries += 1
            retry if tries < 4
        rescue Exception => e
            ap '--------------------'
            puts 'Method: ' + method.to_s
            puts 'Args:'
            ap args

            ap e
            ap e.faultCode
            ap e.faultString
            ap e.backtrace
            ap '--------------------'
        end
    end

end

end
end
end
end
