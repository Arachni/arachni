=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# @param (see Arachni::Processes::Manager#kill_em)
# @return (see Arachni::Processes::Manager#kill_em)
def process_kill_em( *args )
    Arachni::Processes::Manager.kill_em( *args )
end

# @param (see Arachni::Processes::Manager#kill)
# @return (see Arachni::Processes::Manager#kill)
def process_kill( *args )
    Arachni::Processes::Manager.kill( *args )
end

# @param (see Arachni::Processes::Manager#killall)
# @return (see Arachni::Processes::Manager#killall)
def process_killall( *args )
    Arachni::Processes::Manager.killall( *args )
end

# @param (see Arachni::Processes::Manager#kill_many)
# @return (see Arachni::Processes::Manager#kill_many)
def process_kill_many( *args )
    Arachni::Processes::Manager.kill_many( *args )
end

# @param (see Arachni::Processes::Manager#quiet_fork)
# @return (see Arachni::Processes::Manager#quiet_fork)
def process_quiet_fork( *args, &block )
    Arachni::Processes::Manager.quiet_fork( *args, &block )
end

# @param (see Arachni::Processes::Manager#fork_em)
# @return (see Arachni::Processes::Manager#fork_em)
def process_fork_em( *args, &block )
    Arachni::Processes::Manager.fork_em( *args, &block )
end
