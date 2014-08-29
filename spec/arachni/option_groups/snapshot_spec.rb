require 'spec_helper'

describe Arachni::OptionGroups::Snapshot do
    include_examples 'option_group'
    subject { described_class.new }

    %w(save_path).each do |method|
        it { should respond_to method }
        it { should respond_to "#{method}=" }
    end
end
