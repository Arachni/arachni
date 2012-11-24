require_relative '../../spec_helper'
require Arachni::Options.dir['lib'] + 'buffer'

describe Arachni::Buffer::Base do
    before( :all ) do
        @buffer = Arachni::Buffer::Base
    end

    describe '#initialize' do
        context 'when passed a max_size' do
            it 'should be used to determine whether or not the buffer is full' do
                b = @buffer.new( 10 )
                20.times { |i| b << i }
                b.full?.should be_true
            end
        end

        context 'when passed a type' do
            it 'should be used for internal storage' do
                b = @buffer.new( 10, Set )
                b << 'test'
                b << 'test'
                b.size.should == 1
                b.flush.class.should == Set

                b = @buffer.new
                b << 'test'
                b << 'test'
                b.size.should == 2

                b.flush.class.should == Array
            end
        end
    end

    describe '#<<' do
        it 'should add an element to the buffer' do
            b = @buffer.new
            b << 'test'
            b << 'test'
            b.size.should == 2
        end
        it 'should be aliased to #push' do
            b = @buffer.new
            b.push 'test'
            b.push 'test'
            b.size.should == 2
        end
    end

    describe '#batch_push' do
        it 'should push a batch of entries' do
            b = @buffer.new
            b.batch_push [ 'test', 'test2' ]
            b.size.should == 2
        end
    end

    describe '#size' do
        it 'should return the number of entries in the buffer' do
            b = @buffer.new
            b.batch_push [ 'test', 'test2', 'test3' ]
            b.size.should == 3
        end
    end

    describe '#empty?' do
        context 'when the buffer' do
            context 'is empty' do
                it 'should return true' do
                    b = @buffer.new( 10 )
                    b.empty?.should be_true
                end
            end
            context 'is not empty' do
                it 'should return false' do
                    b = @buffer.new( 10 )
                    b << 1
                    b.empty?.should be_false
                end
            end
        end
    end

    describe '#full?' do
        context 'when the buffer has' do
            context 'reached its maximum size' do
                it 'should return true' do
                    b = @buffer.new( 10 )
                    20.times { |i| b << i }
                    b.full?.should be_true
                end
            end
            context 'not reached its maximum size' do
                it 'should return false' do
                    b = @buffer.new( 100 )
                    20.times { |i| b << i }
                    b.full?.should be_false
                end
            end
        end
    end

    describe '#flush' do
        it 'should return a copy of the buffer and then empty the internal one' do
            b = @buffer.new
            b.batch_push [ 'test', 'test2', 'test3' ]
            b.size.should == 3

            b.flush.should == [ 'test', 'test2', 'test3' ]
            b.size.should == 0
        end
    end

    describe '#on_push' do
        it 'should add blocks to be called every time #<< (or #push) is called' do
            item = :ya

            b = @buffer.new

            call_args = []
            b.on_push do |buffer|
                call_args << buffer
            end.should == b

            b.on_push do |buffer|
                call_args << buffer
            end.should == b

            b << item
            call_args.should == [ item, item]

            b = @buffer.new

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
        it 'should add blocks to be called every time #batch_push is called' do
            item = [:ya, :ya1]

            b = @buffer.new

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
        it 'should add blocks to be called every time #flush is called' do
            item = :ya

            b = @buffer.new
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
