def server_port_for( name )
    @@servers[name][:port]
end

def server_url_for( name )
    start_server!( name ) if !@@servers_running.include?( name )
    'http://localhost:' + server_port_for( name ).to_s
end

def start_server!( name )
    @@servers_running << name

    @@server_pids << fork {
        exec 'ruby', @@servers[name][:path], '-p ' + @@servers[name][:port].to_s
    }

    require 'net/http'
    begin
        up = []
        Timeout::timeout( 10 ) do
            loop do

                url = server_url_for( name )
                begin
                    response = Net::HTTP.get_response( URI.parse( url ) )
                    return
                rescue SystemCallError => error
                end

                sleep 0.1
            end
        end
    rescue Timeout::Error => error
        abort "Server never started!"
    end
end

def start_servers!
    @@servers.each { |name, info| start_server!( name ) }
end

def reload_servers!
    kill_servers!
    start_servers!
end

def kill_servers!
    @@server_pids.compact.map { |pid| Process.kill( 'INT', pid ) }
end
