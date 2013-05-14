require 'spec_helper'

describe Set do

    describe '#pop' do
        it 'removes and returns an item from the set' do
            set = described_class.new
            set << 1
            set.size.should == 1
            set.pop.should == 1
            set.size.should == 0
        end
    end

end
