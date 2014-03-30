require 'spec_helper'

describe Arachni::State::Audit do
    after(:each) do
        FileUtils.rm_rf @dump_directory if @dump_directory
    end

    subject { described_class.new }
    let(:audit_id) { 'super-special-audit-operation' }
    let(:dump_directory) do
        @dump_directory = "#{Dir.tmpdir}/audit-#{Arachni::Utilities.generate_token}"
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
            it 'returns false' do
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
            it 'returns true' do
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

    describe '#dump' do
        it 'stores to disk' do
            subject << audit_id
            subject << "#{audit_id}2"
            subject.dump( dump_directory )
        end
    end

    describe '.load' do
        it 'restores from disk' do
            subject << audit_id
            subject << "#{audit_id}2"
            subject.dump( dump_directory )

            subject.should == described_class.load( dump_directory )
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
