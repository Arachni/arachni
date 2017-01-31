=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'rack/test'
# require 'simplecov'
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
Arachni::UI::Output.debug_on( 999999 )
# ...but don't actually print anything.
Arachni::UI::Output.mute

# Uncomment to show output from spawned processes.
Arachni::Processes::Manager.preserve_output

RSpec::Core::MemoizedHelpers.module_eval do
    alias to should
    alias to_not should_not
end

RSpec.configure do |config|
    config.run_all_when_everything_filtered = true
    config.color = true
    config.add_formatter :documentation
    config.include PageHelpers
    config.alias_example_to :expect_it

    config.mock_with :rspec do |mocks|
        mocks.yield_receiver_to_any_instance_implementation_blocks = true
    end

    config.before( :all ) do
        killall
        reset_all
    end

    config.after( :suite ) do
        killall
    end
end
