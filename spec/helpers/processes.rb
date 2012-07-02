require 'ostruct'

def pids
    @@proc_pids ||= []
end

def blocks
    @@blocks ||= {}
end

def kill_processes
    kill_dispatchers
    while p = pids.pop
        blocks.delete( p )
        kill( p )
    end
end

def fork_proc( *args, &b )
    wrap = proc {
        $stdout.reopen('/dev/null', 'w')
        $stderr.reopen('/dev/null', 'w')
        b.call
    }
    pids << fork( *args, &wrap )
    Process.detach( pids.last )
    blocks[pids.last] = b
end

def exec_dispatcher( opts = Arachni::Options.instance, &block )
    fork_proc {
        block.call( opts ) if block_given?
        pid = spawn( "#{opts.dir['root']}/bin/arachni_rpcd --serialized-opts='#{opts.serialize}'" )
        Process.detach( pid )
    }
    #sleep 3
    url = opts.rpc_address + ':' + opts.rpc_port.to_s
    d_opts = OpenStruct.new
    d_opts.max_retries = 0
    begin
        Timeout.timeout( 10 ) {
            while sleep( 0.1 )
                begin
                    Arachni::RPC::Client::Dispatcher.new( d_opts, url ).alive?
                    break
                rescue Exception
                end
            end
        }
    rescue Timeout::Error
        abort "Dispatcher '#{url}' never started!"
    end

    detach_dispatcher( opts )
end

def dispatchers
    @@dispatchers ||= []
end

def detach_dispatcher( dispatcher )
    client = if dispatcher.is_a?( String )
        dispatcher
     elsif dispatcher.is_a?( Arachni::Options )
        dispatcher.rpc_address + ':' + dispatcher.rpc_port.to_s
     else
        dispatcher.url
    end

    dispatchers << client
end

def kill_dispatchers
    d_opts = OpenStruct.new
    d_opts.max_retries = 0
    dispatchers.each do |url|
        begin
            d = Arachni::RPC::Client::Dispatcher.new( d_opts, url )
            d.stats['consumed_pids'].each { |p| pids << p }
            pids << d.proc_info['pid'].to_i
        rescue Exception
        end
    end
end

def kill( pid )
    begin
        10.times { Process.kill( 'KILL', pid ) }
        return false
    rescue Errno::ESRCH
        return true
    end
end

def kill_em
    while ::EM.reactor_running?
        ::EM.stop
        sleep( 0.1 )
    end
end

def fork_em( *args, &b )
    wrap = proc {
        $stdout.reopen('/dev/null', 'w')
        $stderr.reopen('/dev/null', 'w')
        b.call
    }
    pids << ::EM.fork_reactor( *args, &wrap )
    Process.detach( pids.last )
    blocks[pids.last] = b
    pids.last
end
