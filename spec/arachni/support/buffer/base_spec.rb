require 'spec_helper'

describe Arachni::Support::Buffer::Base do

    describe '#initialize' do
        context 'when passed a max_size' do
            it 'determines whether or not the buffer is full' do
                b = described_class.new( 10 )
                20.times { |i| b << i }
                expect(b.full?).to be_truthy
            end
        end

        context 'when passed a type' do
            it 'determines the type to use for internal storage' do
                b = described_class.new( 10, Set )
                b << 'test'
                b << 'test'
                expect(b.size).to eq(1)
                expect(b.flush.class).to eq(Set)

                b = described_class.new
                b << 'test'
                b << 'test'
                expect(b.size).to eq(2)

                expect(b.flush.class).to eq(Array)
            end
        end
    end

    describe '#<<' do
        it 'adds an element to the buffer' do
            b = described_class.new
            b << 'test'
            b << 'test'
            expect(b.size).to eq(2)
        end
        it 'aliased to #push' do
            b = described_class.new
            b.push 'test'
            b.push 'test'
            expect(b.size).to eq(2)
        end
    end

    describe '#batch_push' do
        it 'pushes a batch of entries' do
            b = described_class.new
            b.batch_push [ 'test', 'test2' ]
            expect(b.size).to eq(2)
        end
    end

    describe '#size' do
        it 'returns the number of entries in the buffer' do
            b = described_class.new
            b.batch_push [ 'test', 'test2', 'test3' ]
            expect(b.size).to eq(3)
        end
    end

    describe '#empty?' do
        context 'when the buffer' do
            context 'is empty' do
                it 'returns true' do
                    b = described_class.new( 10 )
                    expect(b.empty?).to be_truthy
                end
            end
            context 'is not empty' do
                it 'returns false' do
                    b = described_class.new( 10 )
                    b << 1
                    expect(b.empty?).to be_falsey
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
                    expect(b.full?).to be_truthy
                end
            end
            context 'not reached its maximum size' do
                it 'returns false' do
                    b = described_class.new( 100 )
                    20.times { |i| b << i }
                    expect(b.full?).to be_falsey
                end
            end
        end
    end

    describe '#flush' do
        it 'returns buffer contents' do
            b = described_class.new
            b.batch_push [ 'test', 'test2', 'test3' ]
            expect(b.size).to eq(3)

            expect(b.flush).to eq([ 'test', 'test2', 'test3' ])
            expect(b.size).to eq(0)
        end
        it 'empties the buffer' do
            b = described_class.new
            b.batch_push [ 'test', 'test2', 'test3' ]
            expect(b.size).to eq(3)

            expect(b.flush).to eq([ 'test', 'test2', 'test3' ])
            expect(b.size).to eq(0)
        end
    end

    describe '#on_push' do
        it 'adds blocks to be called every time #<< (or #push) is called' do
            item = :ya

            b = described_class.new

            call_args = []
            expect(b.on_push do |buffer|
                call_args << buffer
            end).to eq(b)

            expect(b.on_push do |buffer|
                call_args << buffer
            end).to eq(b)

            b << item
            expect(call_args).to eq([ item, item])

            b = described_class.new

            call_args = []
            expect(b.on_push do |buffer|
                call_args << buffer
            end).to eq(b)

            expect(b.on_push do |buffer|
                call_args << buffer
            end).to eq(b)

            b.push item
            expect(call_args).to eq([ item, item])
        end
    end

    describe '#on_batch_push' do
        it 'adds blocks to be called every time #batch_push is called' do
            item = [:ya, :ya1]

            b = described_class.new

            call_args = []
            expect(b.on_batch_push do |buffer|
                call_args << buffer
            end).to eq(b)

            expect(b.on_batch_push do |buffer|
                call_args << buffer
            end).to eq(b)

            b.batch_push item
            expect(call_args).to eq([ item, item])
        end
    end

    describe '#on_flush' do
        it 'adds blocks to be called every time #flush is called' do
            item = :ya

            b = described_class.new
            b << item

            call_args = []
            expect(b.on_flush do |buffer|
                call_args << buffer
            end).to eq(b)

            expect(b.on_flush do |buffer|
                call_args << buffer
            end).to eq(b)

            b.flush
            expect(call_args).to eq([ [item], [item]])
        end
    end
end
