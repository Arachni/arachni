require 'spec_helper'

describe Arachni::OptionGroups::Login do
    include_examples 'option_group'
    subject { described_class.new }

    %w(check_url check_pattern).each do |method|
        it { should respond_to method }
        it { should respond_to "#{method}=" }
    end
end
