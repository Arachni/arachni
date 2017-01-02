=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @param (see Arachni::Processes::Dispatchers#spawn)
# @return (see Arachni::Processes::Dispatchers#spawn)
def dispatcher_spawn( *args )
    Arachni::Processes::Dispatchers.spawn( *args )
end

# @param (see Arachni::Processes::Dispatchers#light_spawn)
# @return (see Arachni::Processes::Dispatchers#light_spawn)
def dispatcher_light_spawn( *args )
    Arachni::Processes::Dispatchers.light_spawn( *args )
end

# @param (see Arachni::Processes::Dispatchers#kill)
# @return (see Arachni::Processes::Dispatchers#kill)
def dispatcher_kill( *args )
    Arachni::Processes::Dispatchers.kill( *args )
end

def dispatcher_kill_by_instance( instance )
    dispatcher_kill instance.options.datastore.dispatcher_url
end

# @param (see Arachni::Processes::Dispatchers#killall)
# @return (see Arachni::Processes::Dispatchers#killall)
def dispatcher_killall
    Arachni::Processes::Dispatchers.killall
end

# @param (see Arachni::Processes::Dispatchers#connect)
# @return (see Arachni::Processes::Dispatchers#connect)
def dispatcher_connect( *args )
    Arachni::Processes::Dispatchers.connect( *args )
end
