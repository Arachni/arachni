require 'net/http'

def server_port_for( name )
    @@servers[name][:port]
end

def server_url_for( name, lazy_start = true )
    name = name.to_s.to_sym
    start_server( name ) if lazy_start && !server_running?( name )
    'http://localhost:' + server_port_for( name ).to_s
end

def start_server( name )
    @@server_pids << fork {
        $stdout.reopen('/dev/null', 'w')
        $stderr.reopen('/dev/null', 'w')
        exec 'ruby', @@servers[name][:path], '-p ' + @@servers[name][:port].to_s
    }
    Process.detach( @@server_pids.last )

    begin
        Timeout::timeout( 10 ) { sleep 0.1 while !server_running?( name ) }
    rescue Timeout::Error
        abort "Server '#{name}' never started!"
    end
end

def server_running?( name )
    url = server_url_for( name, false )
    begin
        Net::HTTP.get_response( URI.parse( url ) )
        true
    rescue Errno::ECONNRESET
        true
    rescue
        false
    end
end

def start_servers
    @@servers.each { |name, info| start_server( name ) }
end

def reload_servers
    kill_servers
    start_servers
end

def kill_servers
    @@server_pids.compact!
    while p = @@server_pids.pop
        kill( p )
    end
end
