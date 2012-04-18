
def pids
    @@proc_pids ||= []
end

def blocks
    @@blocks ||= {}
end

def kill_processes!
    pids.each { |p| blocks.delete( p ); Process.kill( 'KILL', p ) rescue nil }
end

def fork_proc( *args, &b )
    pids << fork( *args, &b )
    blocks[pids.last] = b
end

def exec_dispatcher( opts )
    pids << spawn( "#{opts.dir['root']}/bin/arachni_rpcd --serialized-opts='#{opts.serialize}'" )
end

def fork_em( *args, &b )
    pids << ::EM.fork_reactor( *args, &b )
    blocks[pids.last] = b
end
