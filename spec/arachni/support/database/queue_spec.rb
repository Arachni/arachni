require 'spec_helper'

describe Arachni::Support::Database::Queue do

    before :each do
        @queue = described_class.new
    end
    subject { @queue }
    after :each do
        @queue.clear
    end

    describe '#empty?' do
        context 'when the queue is empty' do
            it 'returns true' do
                subject.empty?.should be_true
            end
        end

        context 'when the queue is not empty' do
            it 'returns false' do
                subject << :stuff
                subject.empty?.should be_false
            end
        end
    end

    describe '#<<' do
        it 'pushes an object' do
            subject << :stuff
            subject.pop.should == :stuff
        end
    end

    describe '#push' do
        it 'pushes an object' do
            subject.push :stuff
            subject.pop.should == :stuff
        end
    end

    describe '#enq' do
        it 'pushes an object' do
            subject.enq :stuff
            subject.pop.should == :stuff
        end
    end

    describe '#pop' do
        it 'removes an object' do
            subject << :stuff
            subject.pop.should == :stuff
        end

        it 'blocks until an entry is available' do
            val = nil

            t = Thread.new { val = subject.pop }
            sleep 1
            Thread.new { subject << :stuff }
            t.join

            val.should == :stuff
        end
    end

    describe '#deq' do
        it 'removes an object' do
            subject << :stuff
            subject.deq.should == :stuff
        end
    end

    describe '#shift' do
        it 'removes an object' do
            subject << :stuff
            subject.shift.should == :stuff
        end
    end

    describe '#size' do
        it 'returns the size of the queue' do
            10.times { |i| subject << i }
            subject.size.should == 10
        end
    end

    describe '#clear' do
        it 'empties the queue' do
            10.times { |i| subject << i }
            subject.clear
            subject.size.should == 0
        end
    end

end
