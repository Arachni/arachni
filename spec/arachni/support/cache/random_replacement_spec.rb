require 'spec_helper'

describe Arachni::Support::Cache::RandomReplacement do

    before { @cache = described_class.new }

    it 'prunes itself by removing random entries (Random Replacement)' do
        @cache.max_size = 3

        k = [ :k, :k2, :k3, :k4 ]
        @cache[k[0]] = '1'
        @cache[k[1]] = '2'
        @cache[k[2]] = '3'
        @cache[k[3]] = '4'
        @cache.size.should == 3

        k.map { |key| @cache[key] }.count( nil ).should == 1

        @cache.clear

        @cache.max_size = 1
        @cache[k[0]]  = '1'
        @cache[k[1]] = '3'
        @cache[k[2]] = '4'
        @cache.size.should == 1

        k[0...3].map { |key| @cache[key] }.count( nil ).should == 2
    end

    describe '#[]=' do
        it 'stores an object' do
            v = 'val'
            (@cache[:key] = v).should == v
            @cache[:key].should == v
        end
        it 'alias of #store' do
            v = 'val2'
            @cache.store( :key2, v ).should == v
            @cache[:key2].should == v
        end
    end

end
