=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @param (see Arachni::Processes::Manager#kill_reactor)
# @return (see Arachni::Processes::Manager#kill_reactor)
def process_kill_reactor( *args )
    Arachni::Processes::Manager.kill_reactor( *args )
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
