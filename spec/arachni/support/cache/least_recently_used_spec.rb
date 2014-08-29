require 'spec_helper'

describe Arachni::Support::Cache::LeastRecentlyUsed do
    it_behaves_like 'cache'

    it 'prunes itself by removing Least Recently Used entries' do
        subject.max_size = 3

        subject[:k]  = '1'
        subject[:k2] = '2'
        subject[:k3] = '3'
        subject[:k4] = '4'
        subject.size.should == 3

        subject[:k4].should be_true
        subject[:k3].should be_true
        subject[:k2].should be_true
        subject[:k].should be_nil

        subject.clear

        subject.max_size = 1
        subject[:k]  = '1'
        subject[:k2] = '3'
        subject[:k3] = '4'
        subject.size.should == 1

        subject[:k3].should be_true
        subject[:k2].should be_nil
        subject[:k].should be_nil
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

    describe '#[]' do
        it 'retrieves an object by key' do
            v = 'val2'
            subject[:key] = v
            subject[:key].should == v
            subject.empty?.should be_false
        end

        context 'when the key does not exist' do
            it 'returns nil' do
                subject[:some_key].should be_nil
            end
        end
    end

    describe '#delete' do
        context 'when the key exists' do
            it 'deletes a key and return its value' do
                v = 'my_val'
                subject[:my_key] = v
                subject.delete( :my_key ).should == v
                subject[:my_key].should be_nil
                subject.include?( :my_key ).should be_false
            end
        end
        context 'when the key does not exist' do
            it 'returns nil' do
                subject.delete( :my_key2 ).should be_nil
            end
        end
    end

    describe '#clear' do
        it 'empties the cache' do
            subject[:my_key2] = 'v'
            subject.size.should > 0
            subject.empty?.should be_false
            subject.clear

            subject.size.should == 0
            subject.empty?.should be_true
        end
    end

end
