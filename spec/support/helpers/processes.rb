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

def killall
    instance_killall
    dispatcher_killall
    web_server_killall
    process_killall
    process_kill_em
end

def process_kill_em( *args )
    Arachni::Processes::Manager.kill_em( *args )
end

def process_kill( *args )
    Arachni::Processes::Manager.kill( *args )
end

def process_killall( *args )
    Arachni::Processes::Manager.killall( *args )
end

def process_kill_many( *args )
    Arachni::Processes::Manager.kill_many( *args )
end

def process_quiet_fork( *args, &block )
    Arachni::Processes::Manager.quiet_fork( *args, &block )
end

def process_fork_em( *args, &block )
    Arachni::Processes::Manager.fork_em( *args, &block )
end
