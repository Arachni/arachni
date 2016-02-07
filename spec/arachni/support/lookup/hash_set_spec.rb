require 'spec_helper'

describe Arachni::Support::LookUp::HashSet do
    it_behaves_like 'lookup'

    describe '#merge' do
        it 'merges 2 sets' do
            new = described_class.new

            subject << 'test'
            new     << 'test2'

            subject.merge new
            expect(subject).to include 'test'
            expect(subject).to include 'test2'
        end
    end

    describe '#replace' do
        it 'replaces the contents of the set with another' do
            new = described_class.new

            subject << 'test'
            new     << 'test2'

            subject.replace new
            expect(subject).to include 'test2'
            expect(subject.include?( 'test' )).to be_falsey
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
                expect(new).to be_superset subject
            end
        end

        context 'when the set is not a superset of another set' do
            it 'returns true' do
                expect(subject).to be_superset new
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
                expect(subject).to be_subset new
            end
        end

        context 'when the set is not a subset of another set' do
            it 'returns true' do
                expect(new).to be_subset subject
            end
        end
    end
end
