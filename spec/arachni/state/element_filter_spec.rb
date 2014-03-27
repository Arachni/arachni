require 'spec_helper'

describe Arachni::State::ElementFilter do
    subject { described_class.new }

    %w(forms links cookies).each do |type|
        describe "##{type}" do
            it "returns a #{Arachni::Support::LookUp::HashSet}" do
                subject.send(type).should be_kind_of Arachni::Support::LookUp::HashSet
            end
        end
    end

    describe '#clear' do
        %w(forms links cookies).each do |type|
            it "clears ##{type}" do
                subject.send(type) << 'stuff'
                subject.send(type).should_not be_empty
                subject.clear
                subject.send(type).should be_empty
            end
        end
    end
end
