def issues
    Arachni::Module::Manager.results
end

def name_from_filename
    File.basename( caller.first.split( ':' ).first, '_spec.rb' )
end

def spec_path
    @@root
end

def fixtures_path
    "#{spec_path}/fixtures/"
end

def run_http
    Arachni::HTTP.run
end

def random_port
    loop do
        port = 5555 + rand( 9999 )
        begin
            socket = Socket.new( :INET, :STREAM, 0 )
            socket.bind( Addrinfo.tcp( "127.0.0.1", port ) )
            socket.close
            return port
        rescue Errno::EADDRINUSE => e
        end
    end
end

def reset_options
    opts = Arachni::Options.instance
    opts.reset
    opts.rpc_address = 'localhost'
    opts.dir['plugins'] = spec_path + 'fixtures/plugins/'
    opts.dir['modules'] = spec_path + 'fixtures/modules/'
    opts.dir['logs']    = spec_path + 'logs/'
end
