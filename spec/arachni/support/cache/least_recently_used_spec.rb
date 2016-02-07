require 'spec_helper'

describe Arachni::Support::Cache::LeastRecentlyUsed do
    it_behaves_like 'cache'

    it 'prunes itself by removing Least Recently Used entries' do
        subject.max_size = 3

        subject[:k]  = '1'
        subject[:k2] = '2'
        subject[:k]
        subject[:k3] = '3'
        subject[:k4] = '4'

        expect(subject.size).to eq(3)

        expect(subject[:k]).to be_truthy
        expect(subject[:k4]).to be_truthy
        expect(subject[:k3]).to be_truthy
        expect(subject[:k2]).to be_nil
    end

    describe '#[]=' do
        it 'stores an object' do
            v = 'val'
            expect(subject[:key] = v).to eq(v)
            expect(subject[:key]).to eq(v)
        end
        it 'alias of #store' do
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

    describe '#delete' do
        context 'when the key exists' do
            it 'deletes a key and return its value' do
                v = 'my_val'
                subject[:my_key] = v
                expect(subject.delete( :my_key )).to eq(v)
                expect(subject[:my_key]).to be_nil
                expect(subject.include?( :my_key )).to be_falsey
            end
        end
        context 'when the key does not exist' do
            it 'returns nil' do
                expect(subject.delete( :my_key2 )).to be_nil
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

end
