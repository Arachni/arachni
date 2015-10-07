require 'spec_helper'

describe Arachni::Support::Cache::RandomReplacement do
    it_behaves_like 'cache'

    it 'prunes itself by removing random entries (Random Replacement)' do
        subject.max_size = 3

        k = [ :k, :k2, :k3, :k4 ]
        subject[k[0]] = '1'
        subject[k[1]] = '2'
        subject[k[2]] = '3'
        subject[k[3]] = '4'
        expect(subject.size).to eq(3)

        expect(k.map { |key| subject[key] }.count( nil )).to eq(1)

        subject.clear

        subject.max_size = 1
        subject[k[0]]  = '1'
        subject[k[1]] = '3'
        subject[k[2]] = '4'
        expect(subject.size).to eq(1)

        expect(k[0...3].map { |key| subject[key] }.count( nil )).to eq(2)
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
