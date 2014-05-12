=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'childprocess'

class WebServerManager
    include Singleton
    include Arachni::Utilities

    attr_reader   :lib
    attr_accessor :address

    def initialize
        @lib     = "#{support_path}/servers/"
        @servers = {}
        @consumed_ports = Set.new

        Dir.glob( File.join( @lib + '**', '*.rb' ) ) do |path|
            {} while @consumed_ports.include?( (port = available_port) )
            @consumed_ports << port

            @servers[normalize_name( File.basename( path, '.rb' ) )] = {
                port: port,
                path: path
            }
        end

        ChildProcess.posix_spawn = true
    end

    def spawn( name, port = nil )
        server_info           = data_for( name )
        server_info[:port]    = port if port
        server_info[:process] = ChildProcess.build(
            RbConfig.ruby, server_info[:path], '-p', server_info[:port].to_s,
            '-o', address_for( name )
        )
        server_info[:process].detach = true
        server_info[:process].start

        begin
            Timeout::timeout( 30 ) { sleep 0.1 while !up?( name ) }
        rescue Timeout::Error
            abort "Server '#{name}' never started!"
        end

        url_for( name, false )
    end

    def url_for( name, lazy_start = true )
        spawn( name ) if lazy_start && !up?( name )

        "#{protocol_for( name )}://#{address_for( name )}:#{port_for( name )}"
    end

    def address_for( name )
        @address || '127.0.0.2'
    end

    def port_for( name )
        data_for( name )[:port]
    end

    def protocol_for( name )
        name.to_s.include?( 'https' ) ? 'https' : 'http'
    end

    def kill( name )
        server_info = data_for( name )
        return if !server_info[:process]

        server_info.delete( :process ).stop
    end

    def killall
        @servers.keys.each { |name| kill name }
        nil
    end

    def up?( name )
        Typhoeus.get(
            url_for( name, false ),
            ssl_verifypeer: false,
            ssl_verifyhost: 0
        ).code != 0
    end

    def self.method_missing( sym, *args, &block )
        if instance.respond_to?( sym )
            instance.send( sym, *args, &block )
        else
            super( sym, *args, &block )
        end
    end

    def self.respond_to?( m )
        super( m ) || instance.respond_to?( m )
    end

    private

    def normalize_name( name )
        name.to_s.to_sym
    end

    def data_for( name )
        @servers[normalize_name( name )]
    end

    def set_data_for(name, data)
        @servers[normalize_name(name)] = data
    end

end
