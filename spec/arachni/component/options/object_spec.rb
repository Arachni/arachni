require 'spec_helper'

describe Arachni::Component::Options::Object do
    subject { described_class.new( '' ) }

    %w(value normalize).each do |m|
        describe "##{m}" do
            it 'returns the value as is' do
                [1, 'test', :stuff, [:blah]].each do |value|
                    subject.value = value
                    subject.send(m).should == value
                end
            end
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            subject.type.should == :object
        end
    end

end
