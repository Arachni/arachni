require 'spec_helper'

describe Arachni::Component::Options::Object do
    include_examples 'component_option'
    subject { described_class.new( '' ) }

    %w(value normalize).each do |m|
        describe "##{m}" do
            it 'returns the value as is' do
                [1, 'test', :stuff, [:blah]].each do |value|
                    subject.value = value
                    expect(subject.send(m)).to eq(value)
                end
            end
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            expect(subject.type).to eq(:object)
        end
    end

end
