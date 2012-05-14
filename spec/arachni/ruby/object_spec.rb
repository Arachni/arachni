require_relative '../../spec_helper'

describe Object do
    describe '#deep_clone' do
        it 'should return a deep copy of the object' do
            a = [ [1,2] ]
            b = a.deep_clone
            a[0] << 3

            b.should == [ [1,2] ]
        end
    end
end
