=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

require 'net/http'

class WebServerManager
    include Singleton
    include Arachni::Utilities
    attr_reader :lib

    def initialize
        @lib     = "#{support_path}/servers/"
        @servers = {}

        Dir.glob( File.join( @lib + '**', '*.rb' ) ) do |path|
            @servers[normalize_name( File.basename( path, '.rb' ) )] = {
                port: available_port,
                path: path
            }
        end
    end

    def spawn( name, port = nil )
        server_info        = data_for( name )
        server_info[:port] = port if port
        server_info[:pid] = process_quiet_fork {
            exec 'ruby', server_info[:path], "-p #{server_info[:port]}"
        }

        begin
            Timeout::timeout( 10 ) { sleep 0.1 while !up?( name ) }
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
        '127.0.0.2'
    end

    def port_for( name )
        data_for( name )[:port]
    end

    def protocol_for( name )
        'http'
    end

    def kill( name )
        server_info = data_for( name )
        return if !server_info[:pid]

        r = process_kill( server_info[:pid] )
        server_info.delete( :pid ) if r
        r
    end

    def killall
        @servers.keys.each { |name| kill name }
    end

    def up?( name )
        begin
            Net::HTTP.get_response( URI.parse( url_for( name, false ) ) )
            true
        rescue Errno::ECONNRESET
            true
        rescue
            false
        end
    end

    def self.method_missing( sym, *args, &block )
        if instance.respond_to?( sym )
            instance.send( sym, *args, &block )
        elsif
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
