require 'spec_helper'

describe Arachni::Support::Buffer::Base do

    describe '#initialize' do
        context 'when passed a max_size' do
            it 'determines whether or not the buffer is full' do
                b = described_class.new( 10 )
                20.times { |i| b << i }
                b.full?.should be_true
            end
        end

        context 'when passed a type' do
            it 'determines the type to use for internal storage' do
                b = described_class.new( 10, Set )
                b << 'test'
                b << 'test'
                b.size.should == 1
                b.flush.class.should == Set

                b = described_class.new
                b << 'test'
                b << 'test'
                b.size.should == 2

                b.flush.class.should == Array
            end
        end
    end

    describe '#<<' do
        it 'adds an element to the buffer' do
            b = described_class.new
            b << 'test'
            b << 'test'
            b.size.should == 2
        end
        it 'aliased to #push' do
            b = described_class.new
            b.push 'test'
            b.push 'test'
            b.size.should == 2
        end
    end

    describe '#batch_push' do
        it 'pushes a batch of entries' do
            b = described_class.new
            b.batch_push [ 'test', 'test2' ]
            b.size.should == 2
        end
    end

    describe '#size' do
        it 'returns the number of entries in the buffer' do
            b = described_class.new
            b.batch_push [ 'test', 'test2', 'test3' ]
            b.size.should == 3
        end
    end

    describe '#empty?' do
        context 'when the buffer' do
            context 'is empty' do
                it 'returns true' do
                    b = described_class.new( 10 )
                    b.empty?.should be_true
                end
            end
            context 'is not empty' do
                it 'returns false' do
                    b = described_class.new( 10 )
                    b << 1
                    b.empty?.should be_false
                end
            end
        end
    end

    describe '#full?' do
        context 'when the buffer has' do
            context 'reached its maximum size' do
                it 'returns true' do
                    b = described_class.new( 10 )
                    20.times { |i| b << i }
                    b.full?.should be_true
                end
            end
            context 'not reached its maximum size' do
                it 'returns false' do
                    b = described_class.new( 100 )
                    20.times { |i| b << i }
                    b.full?.should be_false
                end
            end
        end
    end

    describe '#flush' do
        it 'returns buffer contents' do
            b = described_class.new
            b.batch_push [ 'test', 'test2', 'test3' ]
            b.size.should == 3

            b.flush.should == [ 'test', 'test2', 'test3' ]
            b.size.should == 0
        end
        it 'empties the buffer' do
            b = described_class.new
            b.batch_push [ 'test', 'test2', 'test3' ]
            b.size.should == 3

            b.flush.should == [ 'test', 'test2', 'test3' ]
            b.size.should == 0
        end
    end

    describe '#on_push' do
        it 'adds blocks to be called every time #<< (or #push) is called' do
            item = :ya

            b = described_class.new

            call_args = []
            b.on_push do |buffer|
                call_args << buffer
            end.should == b

            b.on_push do |buffer|
                call_args << buffer
            end.should == b

            b << item
            call_args.should == [ item, item]

            b = described_class.new

            call_args = []
            b.on_push do |buffer|
                call_args << buffer
            end.should == b

            b.on_push do |buffer|
                call_args << buffer
            end.should == b

            b.push item
            call_args.should == [ item, item]
        end
    end

    describe '#on_batch_push' do
        it 'adds blocks to be called every time #batch_push is called' do
            item = [:ya, :ya1]

            b = described_class.new

            call_args = []
            b.on_batch_push do |buffer|
                call_args << buffer
            end.should == b

            b.on_batch_push do |buffer|
                call_args << buffer
            end.should == b

            b.batch_push item
            call_args.should == [ item, item]
        end
    end

    describe '#on_flush' do
        it 'adds blocks to be called every time #flush is called' do
            item = :ya

            b = described_class.new
            b << item

            call_args = []
            b.on_flush do |buffer|
                call_args << buffer
            end.should == b

            b.on_flush do |buffer|
                call_args << buffer
            end.should == b

            b.flush
            call_args.should == [ [item], [item]]
        end
    end
end
