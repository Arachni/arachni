require 'spec_helper'

describe Arachni::OptionGroups::Output do
    include_examples 'option_group'
    subject { described_class.new }

    %w(reroute_to_logfile).each do |method|
        it { is_expected.to respond_to method }
        it { is_expected.to respond_to "#{method}=" }
    end
end
