=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'eventmachine'
require 'em-synchrony'
require "em-synchrony/fiber_iterator"
require 'yaml'

module Arachni
module RPC

    class ConnectionError < Exception; end

module Client

#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
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
            @server.call( call, *args, &block )
        end

    end

    class Handler < EventMachine::Connection
        include EM::P::ObjectProtocol

        attr_reader :callbacks

        def post_init
            start_tls
            @callbacks_mutex = Mutex.new
            @callbacks = {}
        end

        def receive_object( res )
            if cb = get_callback( res )
                cb.call( res['obj'] )
            end
        end

        def set_callback_and_send( obj, &block )
            send_object( obj.merge( 'cb_id' => set_callback( obj, &block ) ) )
        end

        def set_callback( obj, &block )
            @callbacks_mutex.lock

            cb_id = obj.__id__.to_s + ':' + block.__id__.to_s
            @callbacks[cb_id] ||= {}
            @callbacks[cb_id] = block

            return cb_id
        ensure
            @callbacks_mutex.unlock
        end

        def get_callback( obj )
            @callbacks_mutex.lock

            if @callbacks[obj['cb_id']] && cb = @callbacks.delete( obj['cb_id'] )
                return cb
            end

        ensure
            @callbacks_mutex.unlock
        end


        def serializer
            YAML
        end
    end

    def initialize( opts, url, token = nil )

        begin
            @@cache ||= {}

            @opts = opts

            @host, @port = url.split( ':' )
            @k = url

            @token  = token

            @@cache[@k] = ::EM.connect( @host, @port, Handler )
        rescue EventMachine::ConnectionError => e
            exc = ConnectionError.new( e.to_s + " for '#{@k}'." )
            exc.set_backtrace( e.backtrace )
            raise exc
        end
    end

    def call( expr, *args, &block )
        conn = @@cache[@k]

        if !conn
            raise ConnectionError.new( "Can't perform call," +
                " no connection has been established for '#{@k}'." )
        end

        ap '------------'
        puts 'Call: ' + expr
        puts 'Args:'
        ap args
        # puts 'Block: '
        # ap block
#
        # puts 'CB Queue: '
        # ap conn.queue

        # EM.defer {
            obj = {
                'call'  => expr,
                'args'  => args,
                'token' => @token
            }
            conn.set_callback_and_send( obj, &block )
        # }
    end


end

end
end
end