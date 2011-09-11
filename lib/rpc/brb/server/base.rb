=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'brb'
require 'sys/proctable'

module Arachni
module RPC
module BrB
module Server

#
# Base BrB server class
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Base

    class Proxy

        def initialize( server )
            @server = server
        end

        def call( expr, *args )
            @server.call( expr, *args )
        end

    end

    def initialize( opts, token = nil )
        @opts  = opts

        @rpc_address = @opts.rpc_address
        @rpc_port    = @opts.rpc_port

        @proxy = Proxy.new( self )

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
        begin
            loop do
                begin
                    ::BrB::Service.start_service(
                        :object => @proxy,
                        :host   => @rpc_address,
                        :port   => @rpc_port,
                        :verbose => true
                    )
                rescue Exception => e
                    ap e
                end
                sleep 0.2
            end
        rescue Exception => e
            ap e
        end
        # loop{ sleep 1 }
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
        @shutdown = true
        ::EM.stop
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
end
