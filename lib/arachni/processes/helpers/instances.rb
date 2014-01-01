=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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

# @param (see Arachni::Processes::Instances#dispatcher_spawn)
# @return (see Arachni::Processes::Instances#dispatcher_spawn)
def instance_dispatcher_spawn( *args )
    Arachni::Processes::Instances.dispatcher_spawn( *args )
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
