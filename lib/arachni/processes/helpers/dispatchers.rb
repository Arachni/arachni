=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
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
