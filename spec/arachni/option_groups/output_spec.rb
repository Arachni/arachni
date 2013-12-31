require 'spec_helper'

describe Arachni::OptionGroups::Output do
    include_examples 'option_group'
    subject { described_class.new }

    %w(only_positives verbose debug reroute_to_logfile).each do |method|
        it { should respond_to method }
        it { should respond_to "#{method}=" }
    end
end
