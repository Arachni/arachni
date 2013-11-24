=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
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
