=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'eventmachine'
require 'em-synchrony'
require 'yaml'

module Arachni
module RPC
module Server

#
# RPC server class
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Base

    attr_reader :token

    class Proxy < EventMachine::Connection
        include EM::P::ObjectProtocol

        def initialize( server )
            super
            @server = server
        end

        def post_init
            start_tls
        end

        def receive_object( req )

            EM.defer( proc {
                puts "[#{Time.now.asctime}] Request: "
                ap req
                # puts

                if !valid_token?( req['token'] )
                    raise( 'Authentication token missing or invalid.' )
                end

                @server.call( req['call'], *req['args'] )

            }, proc { |obj|

                puts puts "[#{Time.now.asctime}] Response:"
                # ap obj
                # ap '-------'

                EM.defer{ send_object( { 'obj' => obj, 'cb_id' => req['cb_id'] } ) }
            })
        end

        def valid_token?( token )
            return true if token == @server.token
            return false
        end

        def unbind
            @obj = nil
        end

        def serializer
            YAML
        end

    end

    def initialize( opts, token = nil )
        @opts  = opts
        @token = token

        @rpc_address = @opts.rpc_address
        @rpc_port    = @opts.rpc_port

        clear_handlers
    end

    def add_handler( name, obj )
        @objects[name] = obj
        @methods[name] = obj.class.public_instance_methods( false ).map {
            |name|
            name.to_s
        }
    end

    def clear_handlers
        @objects = {}
        @methods = {}
    end

    def run
        puts "Listening on #{@rpc_address}:#{@rpc_port}"
        ::EM.run {
            ::EM.start_server( @rpc_address, @rpc_port, Proxy, self )
        }
    end

    def call( expr, *args )

        meth_name, obj_name = parse_expr( expr )

        if !object_exist?( obj_name )
            raise( "Trying to access non-existent object '#{obj_name}'." )
        end

        if !public_method?( obj_name, meth_name )
            raise( "Trying to access non-public method '#{meth_name}'." )
        end

        @objects[obj_name].send( meth_name.to_sym, *args )
    end

    def alive?
        return true
    end

    def shutdown
        # don't die before returning
        EventMachine::add_timer( 5 ) { ::EM.stop }
        return true
    end

    private

    def parse_expr( expr )
        parts = expr.to_s.split( '.' )

        # method name, object name
        [ parts.pop, parts.join( '.' ) ]
    end

    def object_exist?( obj_name )
        @objects[obj_name] ? true : false
    end

    def public_method?( obj_name, method )
        @methods[obj_name].include?( method )
    end

end

end
end
end
