=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'socket'
require 'sys/proctable'

module Arachni

require Options.instance.dir['lib'] + 'ui/xmlrpcd/xmlrpcd'

module RPC
module XML

#
# Dispatcher class
#
# Dispatches XML-RPC servers on demand providing a centralised environment
# for multiple XMLRPC clients.
#
# The process goes something like this:
#   * a client issues a 'dispatch' call
#   * the dispatcher starts a new XMLRPC server on a random port
#   * the dispatcher returns the port of the XMLRPC server to the client
#   * the client connects to the XMLRPC server listening on that port and does his business
#
# Once the client finishes using the XMLRPC server it *must* shut it down.<br/>
# If it doesn't the system will be eaten away by idle instances of XMLRPC servers.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Dispatcher

    include Arachni::Module::Utilities
    include Arachni::UI::Output
    include ::Sys

    def initialize( opts )

        banner

        if opts.help
            print_help
            exit 0
        end


        @opts = opts

        pkey = ::OpenSSL::PKey::RSA.new( File.read( opts.ssl_pkey ) )         if opts.ssl_pkey
        cert = ::OpenSSL::X509::Certificate.new( File.read( opts.ssl_cert ) ) if opts.ssl_cert

        if opts.ssl_pkey || opts.ssl_pkey
            verification = OpenSSL::SSL::VERIFY_PEER |
                ::OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
        else
            verification = ::OpenSSL::SSL::VERIFY_NONE
        end

        @server = ::WEBrick::HTTPServer.new(
            :Port            => opts.rpc_port || 7331,
            :SSLEnable       => opts.ssl      || false,
            :SSLVerifyClient => verification,
            :SSLCertName     => [ [ "CN", ::WEBrick::Utils::getservername ] ],
            :SSLCertificate  => cert,
            :SSLPrivateKey   => pkey,
            :SSLCACertificateFile => opts.ssl_ca
        )

        @service = ::XMLRPC::WEBrickServlet.new(  )
        @service.add_introspection
        @server.mount( "/RPC2", @service )
        @service.add_handler( ::XMLRPC::iPIMethods( "dispatcher" ), self )

        # trap interupts and exit cleanly when required
        trap( 'HUP' ) { @server.shutdown }
        trap( 'INT' ) { @server.shutdown }

        @jobs = []

    end

    # Starts the dispatcher's server
    def run
        @server.start
    end

    #
    # Creates a new XMLRPC server instance and returns the port number
    #
    # @return   Fixnum  port number on success / false otherwise
    #
    def dispatch
        exception_jail{

            # get an available port for the child
            @opts.rpc_port = avail_port( )

            pid = Kernel.fork {
                server = Arachni::UI::XMLRPCD.new( @opts )
                trap( "INT", "IGNORE" )
                server.run
            }

            @jobs << {
                'pid'  => pid,
                'port' => @opts.rpc_port,
                # 'owner' => ''
            }

            # let the child go about his business
            Process.detach( pid )

            return job( pid )
        }

        return false
    end

    #
    # Returns proc info for a given pid
    #
    # @param    [Fixnum]      pid
    #
    # @return   [Hash]
    #
    def job( pid )
        @jobs.each {
            |cjob|
            return cjob.merge( 'proc' =>  proc( cjob['pid'] ) ) if cjob['pid'] == pid
        }
    end

    #
    # Returns proc info for all jobs
    #
    # @return   [Array<Hash>]
    #
    def jobs
        jobs = []
        @jobs.each {
            |cjob|
            jobs << job( cjob['pid'] )
        }
        return jobs
    end

    #
    # Outputs the Arachni banner.<br/>
    # Displays version number, revision number, author details etc.
    #
    def banner

        puts 'Arachni - Web Application Security Scanner Framework
       Author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
                                      <zapotek@segfault.gr>
               (With the support of the community and the Arachni Team.)

       Website:       http://github.com/Zapotek/arachni
       Documentation: http://github.com/Zapotek/arachni/wiki'
        puts
        puts

    end

    def print_help
        puts <<USAGE
  Usage:  arachni_xmlrpcd_dispatcher.rb \[options\]

  Supported options:

    -h
    --help                      output this

    --port                      specify port to listen to

    SSL --------------------------

    (All SSL options will be honored by the dispatched XMLRPC instances as well.)

    --ssl                       use SSL?

    --ssl_pkey   <file>         location of the SSL private key (.key)

    --ssl_cert   <file>         location of the SSL certificate (.cert)

    --ssl_ca     <file>         location of the CA file (.cert)

USAGE
    end


    private

    def proc( pid )
        struct_to_h( ProcTable.ps( pid ) )
    end

    def struct_to_h( struct )

        hash = {}
        struct.each_pair {
            |k, v|
            v = v.to_s if v.is_a?( Bignum ) || v.is_a?( Fixnum )
            hash[k.to_s] = v
        }

        return hash
    end

    #
    # Returns a random available port
    #
    # @return   Fixnum  port number
    #
    def avail_port

        port = rand_port
        while !avail_port?( port )
            port = rand_port
        end

        return port
    end

    #
    # Returns a random port
    #
    def rand_port
        range = (1025..65535).to_a
        range[ rand( 65535 - 1025 ) ]
    end

    #
    # Checks whether the port number is available
    #
    # @param    Fixnum  port
    #
    # @return   Bool
    #
    def avail_port?( port )
        begin
            socket = Socket.new( :INET, :STREAM, 0 )
            socket.bind( Addrinfo.tcp( "127.0.0.1", port ) )
            socket.close
            return true
        rescue
            return false
        end
    end

end

end
end
end
