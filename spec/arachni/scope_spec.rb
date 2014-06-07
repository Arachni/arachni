require 'spec_helper'

describe Arachni::Scope do

    subject { described_class.new }

    describe '#options' do
        it "returns #{Arachni::OptionGroups::Scope}" do
            subject.options.should be_kind_of Arachni::OptionGroups::Scope
        end
    end

end
