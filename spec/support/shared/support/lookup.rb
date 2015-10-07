require 'spec_helper'

shared_examples_for 'lookup' do
    subject { described_class.new }

    it { is_expected.to respond_to :collection }

    describe '#<<' do
        it 'adds an object and return self' do
            expect(subject << 'test').to eq(subject)
        end
        it 'aliased to #add' do
            expect(subject.add( 'test2' )).to eq(subject)
        end
    end

    describe '#include?' do
        context 'when an object is included' do
            it 'returns true' do
                subject << 'test'
                subject << 'test2'

                expect(subject.include?( 'test' )).to be_truthy
                expect(subject.include?( 'test2' )).to be_truthy
            end
        end
        context 'when an object is not included' do
            it 'returns false' do
                expect(subject.include?( 'test3' )).to be_falsey
            end
        end
    end

    describe '#delete?' do
        it 'deletes an object and return self' do
            subject << 'test'

            expect(subject.include?( 'test' )).to be_truthy
            expect(subject.delete( 'test' )).to be_truthy
            expect(subject.include?( 'test' )).to be_falsey
        end
    end

    describe '#empty?' do
        context 'when empty' do
            it 'returns true' do
                expect(subject.empty?).to be_truthy
            end
        end
        context 'when not empty' do
            it 'returns false' do
                subject << 'test'
                expect(subject.empty?).to be_falsey
            end
        end
    end

    describe '#any?' do
        context 'when empty' do
            it 'returns false' do
                expect(subject.any?).to be_falsey
            end
        end
        context 'when not empty' do
            it 'returns true' do
                subject << 'test'
                expect(subject.any?).to be_truthy
            end
        end
    end

    describe '#size' do
        it 'returns the size' do
            bf = described_class.new
            expect(bf.size).to eq(0)
            bf << '1'
            expect(bf.size).to eq(1)
            bf << '1'
            expect(bf.size).to eq(1)
            bf << '2'
            expect(bf.size).to eq(2)
        end
    end

    describe '#clear' do
        it 'empties the list' do
            bf = described_class.new
            bf << '1'
            bf << '2'
            expect(bf.size).to eq(2)
            bf.clear
            expect(bf.size).to eq(0)
        end
    end

    describe '#==' do
        context 'when 2 lists are equal' do
            it 'returns true' do
                new = described_class.new

                subject << 'test'
                new     << 'test'

                expect(subject).to eq(new)
            end
        end

        context 'when 2 lists are not equal' do
            it 'returns false' do
                new = described_class.new

                subject << 'test'
                new     << 'test2'

                expect(subject).not_to eq(new)
            end
        end
    end

    describe '#hash' do
        context 'when 2 lists are equal' do
            it 'returns the same value' do
                new = described_class.new

                subject << 'test'
                new     << 'test'

                expect(subject.hash).to eq(new.hash)
            end
        end

        context 'when 2 lists are not equal' do
            it 'returns different values' do
                new = described_class.new

                subject << 'test'
                new     << 'test2'

                expect(subject.hash).not_to eq(new.hash)
            end
        end
    end

    describe '#dup' do
        it 'returns a copy' do
            subject << 'test'
            copy = subject.dup

            expect(copy).to eq(subject)

            copy << 'test2'

            expect(copy).not_to eq(subject)
        end
    end
end
