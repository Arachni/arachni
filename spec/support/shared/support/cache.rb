require 'spec_helper'

shared_examples_for 'cache' do
    subject { described_class.new }

    describe '#new' do
        describe 'max_size' do
            describe 'nil' do
                it 'leaves the cache uncapped' do
                    expect(described_class.new.capped?).to be_falsey
                end
            end

            describe 'Integer' do
                it 'imposes a limit to the size of the cache' do
                    expect(described_class.new( 10 ).capped?).to be_truthy
                end
            end
        end
    end

    describe '#max_size' do
        context 'when just initialized' do
            it 'returns nil (unlimited)' do
                expect(subject.max_size).to be_nil
            end
        end
        context 'when set' do
            it 'returns the set value' do
                expect(subject.max_size = 50).to eq(50)
                expect(subject.max_size).to eq(50)
            end
        end
    end

    describe '#uncap' do
        it 'removes the size limit' do
            subject.max_size = 1
            subject.uncap
            subject.max_size = nil
        end
    end

    describe '#capped?' do
        context 'when the cache has no size limit' do
            it 'returns false' do
                subject.uncap
                expect(subject.capped?).to be_falsey
                expect(subject.max_size).to be_nil
            end
        end
        context 'when the cache has a size limit' do
            it 'returns true' do
                subject.max_size = 1
                expect(subject.capped?).to be_truthy
            end
        end
    end

    describe '#uncapped?' do
        context 'when the cache has no size limit' do
            it 'returns true' do
                subject.uncap
                expect(subject.uncapped?).to be_truthy
                expect(subject.max_size).to be_nil
            end
        end
        context 'when the cache has a size limit' do
            it 'returns false' do
                subject.max_size = 1
                expect(subject.max_size).to eq(1)
                expect(subject.uncapped?).to be_falsey
            end
        end
    end

    describe '#uncap' do
        it 'removes the size limit' do
            subject.max_size = 1
            expect(subject.uncapped?).to be_falsey
            expect(subject.max_size).to eq(1)

            subject.uncap
            expect(subject.uncapped?).to be_truthy
            expect(subject.max_size).to be_nil
        end
    end

    describe '#max_size=' do
        it 'sets the maximum size for the cache' do
            expect(subject.max_size = 100).to eq(100)
            expect(subject.max_size).to eq(100)
        end

        context 'when passed < 0' do
            it 'throwes an exception' do
                raised = false
                begin
                    subject.max_size = 0
                rescue
                    raised = true
                end
                expect(raised).to be_truthy
            end
        end
    end

    describe '#size' do
        context 'when the cache is empty' do
            it 'returns 0' do
                expect(subject.size).to eq(0)
            end
        end

        context 'when the cache is not empty' do
            it 'returns a value > 0' do
                subject['stuff'] = [ 'ff ' ]
                expect(subject.size).to be > 0
            end
        end
    end

    describe '#empty?' do
        context 'when the cache is empty' do
            it 'returns true' do
                expect(subject.empty?).to be_truthy
            end
        end
        context 'when the cache is not empty' do
            it 'returns false' do
                subject['stuff2'] = 'ff'
                expect(subject.empty?).to be_falsey
            end
        end
    end

    describe '#any?' do
        context 'when the cache is empty' do
            it 'returns true' do
                expect(subject.any?).to be_falsey
            end
        end
        context 'when the cache is not empty' do
            it 'returns false' do
                subject['stuff3'] = [ 'ff ' ]
                expect(subject.any?).to be_truthy
            end
        end
    end

    describe '#[]=' do
        it 'stores an object' do
            v = 'val'
            expect(subject[:key] = v).to eq(v)
            expect(subject[:key]).to eq(v)
        end
        it 'is alias of #store' do
            v = 'val2'
            expect(subject.store( :key2, v )).to eq(v)
            expect(subject[:key2]).to eq(v)
        end
    end

    describe '#[]' do
        it 'retrieves an object by key' do
            v = 'val2'
            subject[:key] = v
            expect(subject[:key]).to eq(v)
            expect(subject.empty?).to be_falsey
        end

        context 'when the key does not exist' do
            it 'returns nil' do
                expect(subject[:some_key]).to be_nil
            end
        end
    end

    describe '#fetch' do
        context 'when the passed key exists' do
            it 'returns its value' do
                old_val = 'my val'
                new_val = 'new val'

                cache = described_class.new
                cache[:my_key] = old_val
                cache.fetch(:my_key ) { new_val }

                expect(cache[:my_key]).to eq(old_val)
            end
        end

        context 'when the passed key does not exist' do
            it 'assigns to it the return value of the given block' do
                new_val = 'new val'
                cache = described_class.new
                cache.fetch(:my_key ) { new_val }

                expect(cache[:my_key]).to eq(new_val)
            end
        end
    end

    describe '#include?' do
        context 'when the key exists' do
            it 'returns true' do
                subject[:key1] = 'v'
                expect(subject.include?( :key1 )).to be_truthy
            end
        end
        context 'when the key does not exist' do
            it 'returns false' do
                expect(subject.include?( :key2 )).to be_falsey
            end
        end
    end

    describe '#delete' do
        context 'when the key exists' do
            it 'deletes a key' do
                v = 'my_val'
                subject[:my_key] = v
                expect(subject.delete( :my_key )).to eq(v)
                expect(subject[:my_key]).to be_nil
                expect(subject.include?( :my_key )).to be_falsey
            end
            it 'returns its value' do
                v = 'my_val'
                subject[:my_key] = v
                expect(subject.delete( :my_key )).to eq(v)
                expect(subject[:my_key]).to be_nil
                expect(subject.include?( :my_key )).to be_falsey
            end
        end
        context 'when the key does not exist' do
            it 'should return nil' do
                expect(subject.delete( :my_key2 )).to be_nil
            end
        end
    end

    describe '#empty?' do
        context 'when cache is empty' do
            it 'returns true' do
                expect(subject.empty?).to be_truthy
            end
        end
        context 'when cache is not empty' do
            it 'returns false' do
                subject['ee'] = 'rr'
                expect(subject.empty?).to be_falsey
            end
        end
    end

    describe '#any?' do
        context 'when cache is empty' do
            it 'returns false' do
                expect(subject.any?).to be_falsey
            end
        end
        context 'when cache is not empty' do
            it 'returns true' do
                subject['ee'] = 'rr'
                expect(subject.any?).to be_truthy
            end
        end
    end

    describe '#clear' do
        it 'empties the cache' do
            subject[:my_key2] = 'v'
            expect(subject.size).to be > 0
            expect(subject.empty?).to be_falsey
            subject.clear

            expect(subject.size).to eq(0)
            expect(subject.empty?).to be_truthy
        end
    end

    describe '#==' do
        context 'when 2 lists are equal' do
            it 'returns true' do
                new = described_class.new

                subject[:test_key] = 'test_val'
                new[:test_key]     = 'test_val'

                expect(subject).to eq(new)
            end
        end

        context 'when 2 lists are not equal' do
            it 'returns false' do
                new = described_class.new

                subject[:test_key] = 'test_val'
                new[:test_key]     = 'test_val2'

                expect(subject).not_to eq(new)
            end
        end
    end

    describe '#hash' do
        context 'when 2 lists are equal' do
            it 'returns the same value' do
                new = described_class.new

                subject[:test_key] = 'test_val'
                new[:test_key]     = 'test_val'

                expect(subject.hash).to eq(new.hash)
            end
        end

        context 'when 2 lists are not equal' do
            it 'returns different values' do
                new = described_class.new

                subject[:test_key] = 'test_val'
                new[:test_key]     = 'test_val2'

                expect(subject.hash).not_to eq(new.hash)
            end
        end
    end

    describe '#dup' do
        it 'returns a copy' do
            subject[:test_key] = 'test_val'
            copy = subject.dup

            expect(copy).to eq(subject)

            copy[:test_key] = 'test_val2'

            expect(copy).not_to eq(subject)
        end
    end
end
