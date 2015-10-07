require 'spec_helper'

describe Arachni::Component::Options::Port do
    include_examples 'component_option'
    subject { described_class.new( '' ) }

    describe '#valid?' do
        context 'when the path exists' do
            it 'returns true' do
                (1..65535).each do |p|
                    subject.value = p
                    expect(subject.valid?).to be_truthy

                    subject.value = p.to_s
                    expect(subject.valid?).to be_truthy
                end
            end
        end
        context 'when the path does not exist' do
            it 'returns false' do
                ['dd', -1, 0, 9999999].each do |p|
                    subject.value = p
                    expect(subject.valid?).to be_falsey

                    subject.value = p.to_s
                    expect(subject.valid?).to be_falsey
                end

            end
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            expect(subject.type).to eq(:port)
        end
    end

end
