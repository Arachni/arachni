require 'spec_helper'

describe Set do

    describe '#shift' do
        it 'removes and returns an item from the set' do
            set = described_class.new
            set << 1
            expect(set.size).to eq(1)
            expect(set.shift).to eq(1)
            expect(set.size).to eq(0)
        end
    end

end
