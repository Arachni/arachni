require_relative '../../spec_helper'

describe Arachni::Cache::LeastRecentlyUsed do

    before { @cache = Arachni::Cache::LeastRecentlyUsed.new }

    it 'should prune itself by removing Least Recently Used entries' do
        @cache.max_size = 3

        @cache[:k]  = '1'
        @cache[:k2] = '2'
        @cache[:k3] = '3'
        @cache[:k4] = '4'
        @cache.size.should == 3

        @cache[:k4].should be_true
        @cache[:k3].should be_true
        @cache[:k2].should be_true
        @cache[:k].should be_nil

        @cache.clear

        @cache.max_size = 1
        @cache[:k]  = '1'
        @cache[:k2] = '3'
        @cache[:k3] = '4'
        @cache.size.should == 1

        @cache[:k3].should be_true
        @cache[:k2].should be_nil
        @cache[:k].should be_nil
    end

    describe '#[]=' do
        it 'should store an object' do
            v = 'val'
            (@cache[:key] = v).should == v
            @cache[:key].should == v
        end
        it 'should be an alias of #store' do
            v = 'val2'
            @cache.store( :key2, v ).should == v
            @cache[:key2].should == v
        end
    end

    describe '#[]' do
        it 'should retrieve an object by key' do
            v = 'val2'
            @cache[:key] = v
            @cache[:key].should == v
            @cache.empty?.should be_false
        end

        context 'when the key does not exist' do
            it 'should return nil' do
                @cache[:some_key].should be_nil
            end
        end
    end

    describe '#delete' do
        context 'when the key exists' do
            it 'should delete a key and return its value' do
                v = 'my_val'
                @cache[:my_key] = v
                @cache.delete( :my_key ).should == v
                @cache[:my_key].should be_nil
                @cache.include?( :my_key ).should be_false
            end
        end
        context 'when the key does not exist' do
            it 'should return nil' do
                @cache.delete( :my_key2 ).should be_nil
            end
        end
    end

    describe '#clear' do
        it 'should empty the cache' do
            @cache[:my_key2] = 'v'
            @cache.size.should > 0
            @cache.empty?.should be_false
            @cache.clear

            @cache.size.should == 0
            @cache.empty?.should be_true
        end
    end

end
