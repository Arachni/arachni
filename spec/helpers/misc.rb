def issues
    Arachni::Module::Manager.results
end

def spec_path
    @@root
end

def run_http!
    Arachni::HTTP.instance.run
end

def remove_constants( mod, children_only = false )
    return if !(mod.is_a?( Class ) || mod.is_a?( Module )) ||
        !mod.to_s.start_with?( 'Arachni' )

    parent = Object
    mod.to_s.split( '::' )[0..-2].each {
        |ancestor|
        parent = parent.const_get( ancestor.to_sym )
    }

    mod.constants.each { |m| remove_constants( mod.const_get( m ) ) }

    return if children_only
    parent.send( :remove_const, mod.to_s.split( ':' ).last.to_sym )
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

def reset_options
    opts = Arachni::Options.instance
    opts.reset!
    opts.rpc_address = 'localhost'
    opts.dir['plugins'] = spec_path + 'fixtures/plugins/'
    opts.dir['modules'] = spec_path + 'fixtures/modules/'
    opts.dir['logs']    = spec_path + 'logs'
end
