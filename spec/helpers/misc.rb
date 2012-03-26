def issues
    Arachni::Module::Manager.results
end

def spec_path
    @@root
end

def run_http!
    Arachni::HTTP.instance.run
end

def random_port
    loop do
        port = 5555 + rand( 9999 )
        begin
            socket = Socket.new( :INET, :STREAM, 0 )
            socket.bind( Addrinfo.tcp( "127.0.0.1", port ) )
            socket.close
            return port
        rescue
        end
    end
end

def kill_em!
    while ::EM.reactor_running?
        ::EM.stop
        sleep( 0.1 )
    end
end
