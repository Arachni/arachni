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

# Uncomment to show output from the Framework.
require_relative '../lib/arachni/ui/cli/output'
require_relative '../lib/arachni'
require_relative '../lib/arachni/processes'
require_relative '../lib/arachni/processes/helpers'

require_relative 'support/helpers/paths'
require_relative 'support/helpers/requires'

Dir.glob( "#{support_path}/{lib,helpers,shared}/**/*.rb" ).each { |f| require f }

# Uncomment to show output from spawned processes.
#Arachni::Processes::Manager.preserve_output

RSpec.configure do |config|
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.run_all_when_everything_filtered = true
    config.color = true
    config.add_formatter :documentation

    config.before( :all ) do
        #Arachni::UI::Output.mute
        #Arachni::UI::Output.debug_on

        killall
        reset_all
    end

    config.after( :suite ) do
        killall
    end
end
