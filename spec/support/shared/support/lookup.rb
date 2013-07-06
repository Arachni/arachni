require 'spec_helper'

shared_examples_for 'lookup' do
    before( :all ) do
        @bf = described_class.new
    end

    describe '#<<' do
        it 'adds an object and return self' do
            (@bf << 'test').should == @bf
        end
        it 'aliased to #add' do
            @bf.add( 'test2' ).should == @bf
        end
    end

    describe '#include?' do
        context 'when an object is included' do
            it 'returns true' do
                @bf.include?( 'test' ).should be_true
                @bf.include?( 'test2' ).should be_true
            end
        end
        context 'when an object is not included' do
            it 'returns false' do
                @bf.include?( 'test3' ).should be_false
            end
        end
    end

    describe '#delete?' do
        it 'deletes an object and return self' do
            @bf.include?( 'test' ).should be_true
            @bf.delete( 'test' ).should be_true
            @bf.include?( 'test' ).should be_false
        end
    end

    describe '#empty?' do
        context 'when empty' do
            it 'returns true' do
                described_class.new.empty?.should be_true
            end
        end
        context 'when not empty' do
            it 'returns false' do
                @bf.empty?.should be_false
            end
        end
    end

    describe '#size' do
        it 'returns the size' do
            bf = described_class.new
            bf.size.should == 0
            bf << '1'
            bf.size.should == 1
            bf << '1'
            bf.size.should == 1
            bf << '2'
            bf.size.should == 2
        end
    end

    describe '#clear' do
        it 'empties the list' do
            bf = described_class.new
            bf << '1'
            bf << '2'
            bf.size.should == 2
            bf.clear
            bf.size.should == 0
        end
    end

end
