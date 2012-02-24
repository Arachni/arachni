def server_port_for( name )
    @@servers[name][:port]
end

def server_url_for( name )
    'http://localhost:' + server_port_for( name ).to_s
end

def start_servers!
    @@servers.each {
        |name, info|
        @@server_pids << fork {
            exec 'ruby', info[:path], '-p ' + info[:port].to_s
        }
    }

    require 'net/http'
    begin
        up = []
        Timeout::timeout( 10 ) do
            loop do

                @@servers.keys.each {
                    |name|

                    next if up.include? name
                    url = server_url_for( name )
                    begin
                        response = Net::HTTP.get_response( URI.parse( url ) )
                        up << name if response
                    rescue SystemCallError => error
                    end

                }

                if up.size == @@servers.size
                    puts 'Servers are up!'
                    return
                end

                sleep 0.1
            end
        end
    rescue Timeout::Error => error
        abort "Server never started!"
    end
end


def reload_servers!
    kill_servers!
    start_servers!
end


def kill_servers!
    @@server_pids.each { |pid| Process.kill( 'INT', pid ) if pid }
end
