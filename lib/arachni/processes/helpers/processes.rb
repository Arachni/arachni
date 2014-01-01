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
