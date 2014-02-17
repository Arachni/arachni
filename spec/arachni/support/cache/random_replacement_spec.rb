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
        subject.size.should == 3

        k.map { |key| subject[key] }.count( nil ).should == 1

        subject.clear

        subject.max_size = 1
        subject[k[0]]  = '1'
        subject[k[1]] = '3'
        subject[k[2]] = '4'
        subject.size.should == 1

        k[0...3].map { |key| subject[key] }.count( nil ).should == 2
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
