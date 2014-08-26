=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

# @param (see Arachni::Processes::Instances#spawn)
# @return (see Arachni::Processes::Instances#spawn)
def instance_spawn( *args )
    Arachni::Processes::Instances.spawn( *args )
end

# @param (see Arachni::Processes::Instances#grid_spawn)
# @return (see Arachni::Processes::Instances#grid_spawn)
def instance_grid_spawn( *args )
    Arachni::Processes::Instances.grid_spawn( *args )
end

def instance_light_grid_spawn( *args )
    Arachni::Processes::Instances.light_grid_spawn( *args )
end

# @param (see Arachni::Processes::Instances#dispatcher_spawn)
# @return (see Arachni::Processes::Instances#dispatcher_spawn)
def instance_dispatcher_spawn( *args )
    Arachni::Processes::Instances.dispatcher.spawn( *args )
end

def instance_kill( url )
    Arachni::Processes::Instances.kill url
end

# @param (see Arachni::Processes::Instances#killall)
# @return (see Arachni::Processes::Instances#killall)
def instance_killall
    Arachni::Processes::Instances.killall
end

# @param (see Arachni::Processes::Instances#connect)
# @return (see Arachni::Processes::Instances#connect)
def instance_connect( *args )
    Arachni::Processes::Instances.connect( *args )
end

# @param (see Arachni::Processes::Instances#token_for)
# @return (see Arachni::Processes::Instances#token_for)
def instance_token_for( *args )
    Arachni::Processes::Instances.token_for( *args )
end
