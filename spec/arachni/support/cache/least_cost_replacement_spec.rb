require 'spec_helper'

describe Arachni::Support::Cache::LeastCostReplacement do

    before { @cache = described_class.new }


    it 'prunes itself by removing the least costly entries' do
        @cache.max_size = 3

        @cache.store( :k,  '1', :high )
        @cache.store( :k2, '2', :high )
        @cache.store( :k3, '3', :medium )
        @cache.store( :k4, '4', :low )
        @cache.size.should == 3

        @cache[:k4].should be_true
        @cache[:k3].should be_nil
        @cache[:k2].should be_true
        @cache[:k].should be_true

        @cache.clear

        @cache.max_size = 1

        @cache.store( :k,  '1', :medium )
        @cache.store( :k2, '2', :low )
        @cache.store( :k3, '3', :low )
        @cache.store( :k4, '4', :low )
        @cache.size.should == 1

        @cache[:k4].should be_true
        @cache[:k3].should be_nil
        @cache[:k2].should be_nil
        @cache[:k].should be_nil
    end

    describe '#store' do
        it 'stores an object by key' do
            v = 'val'
            @cache.store( :key, v, :low ).should == v
            @cache[:key].should == v
        end
        it 'assigns cost to object' do
            v = 'val'
            @cache.store( :key, v, :low ).should == v
            @cache[:key].should == v
        end
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
