require 'spec_helper'

describe Arachni::Support::Cache::LeastCostReplacement do
    it_behaves_like 'cache'

    it 'prunes itself by removing the least costly entries' do
        subject.max_size = 3

        subject.store( :k,  '1', :high )
        subject.store( :k2, '2', :high )
        subject.store( :k3, '3', :medium )
        subject.store( :k4, '4', :low )
        expect(subject.size).to eq(3)

        expect(subject[:k4]).to be_truthy
        expect(subject[:k3]).to be_nil
        expect(subject[:k2]).to be_truthy
        expect(subject[:k]).to be_truthy

        subject.clear

        subject.max_size = 1

        subject.store( :k,  '1', :medium )
        subject.store( :k2, '2', :low )
        subject.store( :k3, '3', :low )
        subject.store( :k4, '4', :low )
        expect(subject.size).to eq(1)

        expect(subject[:k4]).to be_truthy
        expect(subject[:k3]).to be_nil
        expect(subject[:k2]).to be_nil
        expect(subject[:k]).to be_nil
    end

    describe '#store' do
        it 'stores an object by key' do
            v = 'val'
            expect(subject.store( :key, v, :low )).to eq(v)
            expect(subject[:key]).to eq(v)
        end
        it 'assigns cost to object' do
            v = 'val'
            expect(subject.store( :key, v, :low )).to eq(v)
            expect(subject[:key]).to eq(v)
        end
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
end
