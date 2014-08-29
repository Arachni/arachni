require 'spec_helper'

describe Arachni::Support::Cache::LeastCostReplacement do
    it_behaves_like 'cache'

    it 'prunes itself by removing the least costly entries' do
        subject.max_size = 3

        subject.store( :k,  '1', :high )
        subject.store( :k2, '2', :high )
        subject.store( :k3, '3', :medium )
        subject.store( :k4, '4', :low )
        subject.size.should == 3

        subject[:k4].should be_true
        subject[:k3].should be_nil
        subject[:k2].should be_true
        subject[:k].should be_true

        subject.clear

        subject.max_size = 1

        subject.store( :k,  '1', :medium )
        subject.store( :k2, '2', :low )
        subject.store( :k3, '3', :low )
        subject.store( :k4, '4', :low )
        subject.size.should == 1

        subject[:k4].should be_true
        subject[:k3].should be_nil
        subject[:k2].should be_nil
        subject[:k].should be_nil
    end

    describe '#store' do
        it 'stores an object by key' do
            v = 'val'
            subject.store( :key, v, :low ).should == v
            subject[:key].should == v
        end
        it 'assigns cost to object' do
            v = 'val'
            subject.store( :key, v, :low ).should == v
            subject[:key].should == v
        end
    end

    describe '#[]=' do
        it 'stores an object' do
            v = 'val'
            (subject[:key] = v).should == v
            subject[:key].should == v
        end
        it 'alias of #store' do
            v = 'val2'
            subject.store( :key2, v ).should == v
            subject[:key2].should == v
        end
    end
end
