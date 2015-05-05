=begin
    Copyright 2010-2015 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'simplecov'
require 'faker'

require_relative '../lib/arachni'
require_relative '../ui/cli/output'
require_relative '../lib/arachni/processes'
require_relative '../lib/arachni/processes/helpers'

require_relative 'support/helpers/paths'
require_relative 'support/helpers/requires'

Dir.glob( "#{support_path}/{lib,helpers,shared,factories}/**/*.rb" ).each { |f| require f }

# Enable extra output options in order to get full coverage...
Arachni::UI::Output.verbose_on
Arachni::UI::Output.debug_on( 3 )
# ...but don't actually print anything.
Arachni::UI::Output.mute

# Uncomment to show output from spawned processes.
Arachni::Processes::Manager.preserve_output

RSpec.configure do |config|
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.run_all_when_everything_filtered = true
    config.color = true
    config.add_formatter :documentation
    config.include PageHelpers

    config.before( :all ) do
        killall
        reset_all
    end

    config.after( :suite ) do
        killall
    end
end
