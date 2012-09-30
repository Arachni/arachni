require_relative '../spec_helper'

describe Arachni::BloomFilter do
    before( :all ) do
        @bf = Arachni::BloomFilter.new
    end

    describe '#<<' do
        it 'should add an object and return self' do
            (@bf << 'test').should == @bf
        end
        it 'should be aliased to #add' do
            @bf.add( 'test2' ).should == @bf
        end
    end

    describe '#include?' do
        context 'when an object is included' do
            it 'should return true' do
                @bf.include?( 'test' ).should be_true
                @bf.include?( 'test2' ).should be_true
            end
        end
        context 'when an object is not included' do
            it 'should return false' do
                @bf.include?( 'test3' ).should be_false
            end
        end
    end

    describe '#delete?' do
        it 'should delete an object and return self' do
            @bf.include?( 'test' ).should be_true
            @bf.delete( 'test' ).should be_true
            @bf.include?( 'test' ).should be_false
        end
    end

    describe '#empty?' do
        context 'when empty' do
            it 'should return true' do
                Arachni::BloomFilter.new.empty?.should be_true
            end
        end
        context 'when not empty' do
            it 'should return false' do
                @bf.empty?.should be_false
            end
        end
    end

    describe '#size' do
        it 'should return the size' do
            bf = Arachni::BloomFilter.new
            bf.size.should == 0
            bf << 1
            bf.size.should == 1
            bf << 1
            bf.size.should == 1
            bf << 2
            bf.size.should == 2
        end
    end

    describe '#clear' do
        it 'should empty the list' do
            bf = Arachni::BloomFilter.new
            bf << 1
            bf << 2
            bf.size.should == 2
            bf.clear
            bf.size.should == 0
        end
    end

end
