require 'spec_helper'

describe Arachni::Support::Database::Queue do

    before :each do
        @queue = described_class.new
    end
    subject { @queue }
    after :each do
        @queue.clear
    end

    let(:sample_size) { 2 * subject.max_buffer_size }

    describe "#{described_class}::DEFAULT_MAX_BUFFER_SIZE" do
        it 'returns 100' do
            described_class::DEFAULT_MAX_BUFFER_SIZE.should == 100
        end
    end

    describe '#buffer' do
        it 'returns the objects stored in the memory buffer' do
            subject << 1
            subject << 2

            subject.buffer.should == [1, 2]
        end
    end

    describe '#disk' do
        it 'returns paths to the files of objects stored to disk' do
            subject.max_buffer_size = 0
            subject << 1
            subject << 2

            subject.disk.size.should == 2
            subject.disk.each do |path|
                File.exists?( path ).should be_true
            end
        end
    end

    describe '#max_buffer_size' do
        context 'by default' do
            it "returns #{described_class}::DEFAULT_MAX_BUFFER_SIZE" do
                subject.max_buffer_size.should == described_class::DEFAULT_MAX_BUFFER_SIZE
            end
        end
    end

    describe '#max_buffer_size=' do
        it 'sets #max_buffer_size' do
            subject.max_buffer_size = 10
            subject.max_buffer_size.should == 10
        end
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
            sample_size.times do |i|
                subject << "stuff #{i}"
            end

            sample_size.times do |i|
                subject.pop.should == "stuff #{i}"
            end
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
            sample_size.times do |i|
                subject << "stuff #{i}"
            end

            sample_size.times do |i|
                subject.pop.should == "stuff #{i}"
            end
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
            sample_size.times { |i| subject << i }
            subject.size.should == sample_size
        end
    end

    describe '#buffer_size' do
        it 'returns the size of the in-memory entries' do
            subject.buffer_size.should == 0

            (subject.max_buffer_size - 1).times { |i| subject << i }
            subject.buffer_size.should == subject.max_buffer_size - 1

            subject.clear

            sample_size.times { |i| subject << i }
            subject.buffer_size.should == subject.max_buffer_size
        end
    end

    describe '#disk_size' do
        it 'returns the size of the disk entries' do
            subject.buffer_size.should == 0

            (subject.max_buffer_size + 1).times { |i| subject << i }
            subject.disk_size.should == 1

            subject.clear

            sample_size.times { |i| subject << i }
            subject.disk_size.should == sample_size - subject.max_buffer_size
        end
    end


    describe '#clear' do
        it 'empties the queue' do
            sample_size.times { |i| subject << i }
            subject.clear
            subject.size.should == 0
        end
    end

end
