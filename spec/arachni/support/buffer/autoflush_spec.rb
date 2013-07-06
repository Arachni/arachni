require 'spec_helper'

describe Arachni::Support::Buffer::AutoFlush do
    describe '#initialize' do
        context 'when passed a max_size' do
            context 'when the buffer reaches that size' do
                it 'forces the buffer to #flush itself' do
                    b = described_class.new( 10 )

                    buffers = []
                    b.on_flush do |buffer|
                        buffers << buffer
                    end

                    20.times { |i| b << i }

                    buffers.size.should == 2
                    buffers.shift.should == (0..9).to_a
                    buffers.shift.should == (10...20).to_a

                    b.should be_empty
                end
            end
        end

        context 'when passed a max_pushes' do
            context 'when the amount of pushes reaches that size' do
                it 'forces the buffer to #flush itself' do
                    b = described_class.new( 99999, 10 )

                    buffers = []
                    b.on_flush do |buffer|
                        buffers << buffer
                    end

                    20.times { |i| b << i }

                    buffers.size.should == 2
                    buffers.shift.should == (0..9).to_a
                    buffers.shift.should == (10...20).to_a
                    b.should be_empty

                    b = described_class.new( 99999, 10 )

                    buffers = []
                    b.on_flush do |buffer|
                        buffers << buffer
                    end

                    20.times { |i| b.batch_push (0..1000).to_a }

                    buffers.size.should == 2
                    buffers.shift.should == (0..1000).to_a
                    buffers.shift.should == (0..1000).to_a
                    b.should be_empty
                end
            end
        end

        context 'when passed a type' do
            it 'should be used for internal storage' do
                b = described_class.new( 10, 999, Set )
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

end
