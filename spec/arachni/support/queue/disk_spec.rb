require 'spec_helper'

describe Arachni::Support::Queue::Disk do
    before( :each ) do
        @q = described_class.new
    end
    after( :each ) do
        @q.clear
    end

    it 'handles large data sets' do
        times = 500_000

        2.times do
            pushed = []
            times.times do |i|
                pushed << i
                @q     << i

                @q.size.should == pushed.size
            end

            poped = []
            times.times do |i|
                poped << @q.pop

                @q.size.should == times - poped.size
            end

            poped.sort.should == pushed
        end

        @q.size.should == 0
    end

    describe '#<<' do
        it 'pushes an object to the queue' do
            @q << 'stuff'
        end
        it 'returns self' do
            (@q << 'stuff2').should == @q
        end
    end

    describe '#pop' do
        context 'when the queue is empty' do
            it 'returns nil' do
                @q.pop.should be_nil
            end
        end
        it 'removes and returns an object from queue' do
            @q << 'stuff3'
            @q.pop.should == 'stuff3'
        end
    end

    describe '#size' do
        it 'returns the size of the queue' do
            @q.size.should == 0
            @q << 'stuff3'
            @q.size.should == 1
        end
    end

    describe '#clear' do
        it 'returns the size of the queue' do
            @q << 'stuff3'
            @q.size.should == 1

            @q.clear
            @q.size.should == 0
            @q.pop.should be_nil
        end
    end

    describe '#dup' do
        it 'returns a copy of the queue' do
            q = described_class.new( memory_size: 100 )

            pushed = []
            1_000.times do |i|
                item = i.hash.to_s

                pushed << item
                q      << item
            end

            cq = q.dup
            poped = []
            1_000.times do |i|
                poped << cq.pop
            end

            poped.sort.should == pushed.sort
            q.size.should > 0
            cq.size.should == 0
        end
    end

    describe '#to_a' do
        it 'returns the contents of the queue as an array' do
            q = described_class.new( memory_size: 100 )

            pushed = []
            1_000.times do |i|
                item = i.hash.to_s

                pushed << item
                q      << item
            end

            q.to_a.sort.should == pushed.sort
        end
    end

end
