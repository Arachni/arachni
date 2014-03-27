require 'spec_helper'

describe Arachni::State::Audit do
    subject { described_class.new }
    let(:audit_id) { 'super-special-audit-operation' }

    describe '#<<' do
        it 'pushes a state' do
            subject << audit_id
            subject.should include audit_id
        end
    end

    describe '#<<' do
        it 'pushes a state' do
            subject << audit_id
            subject.should include audit_id
        end
    end

    describe '#include?' do
        context 'when an operation is included' do
            it 'returns true' do
                subject << audit_id
                subject.should include audit_id
            end
        end
        context 'when an operation is not included' do
            it 'returns true' do
                subject << audit_id
                subject.should_not include "#{audit_id}2"
            end
        end
    end

    describe '#empty?' do
        context 'when the list is empty' do
            it 'returns true' do
                subject.should be_empty
            end
        end
        context 'when the list is not empty' do
            it 'returns false' do
                subject << audit_id
                subject.should_not be_empty
            end
        end
    end

    describe '#any?' do
        context 'when the list is empty' do
            it 'returns false' do
                subject.should_not be_any
            end
        end
        context 'when the list is not empty' do
            it 'returns false' do
                subject << audit_id
                subject.should be_any
            end
        end
    end

    describe '#size' do
        it 'returns the size of the list' do
            subject << audit_id
            subject << "#{audit_id}2"
            subject.size.should == 2
        end
    end

    describe '#clear' do
        it 'clears the list' do
            subject << audit_id
            subject.clear
            subject.should be_empty
        end
    end

end
