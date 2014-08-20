require 'spec_helper'

describe Arachni::Support::LookUp::HashSet do
    it_behaves_like 'lookup'

    describe '#merge' do
        it 'merges 2 sets' do
            new = described_class.new

            subject << 'test'
            new     << 'test2'

            subject.merge new
            subject.should include 'test'
            subject.should include 'test2'
        end
    end

    describe '#replace' do
        it 'replaces the contents of the set with another' do
            new = described_class.new

            subject << 'test'
            new     << 'test2'

            subject.replace new
            subject.should include 'test2'
            subject.should_not include 'test'
        end
    end

    describe '#superset?' do
        let(:new) { described_class.new }
        before do
            subject << 'test'
            subject << 'test2'
            subject << 'test3'

            new     << 'test2'
            subject << 'test3'
        end

        context 'when the set is a superset of another set' do
            it 'returns true' do
                new.should be_superset subject
            end
        end

        context 'when the set is not a superset of another set' do
            it 'returns true' do
                subject.should be_superset new
            end
        end
    end

    describe '#subset?' do
        let(:new) { described_class.new }
        before do
            subject << 'test'
            subject << 'test2'
            subject << 'test3'

            new     << 'test2'
            subject << 'test3'
        end

        context 'when the set is a subset of another set' do
            it 'returns true' do
                subject.should be_subset new
            end
        end

        context 'when the set is not a subset of another set' do
            it 'returns true' do
                new.should be_subset subject
            end
        end
    end
end
