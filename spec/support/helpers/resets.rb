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

def reset_options
    opts = Arachni::Options.instance
    opts.reset
    opts.rpc_address = 'localhost'

    opts.dir['plugins']        = fixtures_path + 'plugins/'
    opts.dir['modules']        = fixtures_path + 'modules/'
    opts.dir['fingerprinters'] = fixtures_path + 'fingerprinters/'
    opts.dir['logs']           = spec_path + 'support/logs/'

    opts
end

def reset_all
    Arachni::Framework.reset
    reset_options
    Arachni::HTTP.reset
end

def killall
    instance_killall
    dispatcher_killall
    web_server_killall
    process_killall
    process_kill_em
end
