require_relative '../../spec_helper'

describe Array do
    before( :all ) do
        @arr = Array.new
        50.times { |i| @arr << i }
    end

    describe :chunk do

        it 'should split the array into chunks' do
            chunks = @arr.chunk( 5 )
            chunks.size.should == 5
            chunks.each { |c| c.size.should == 10 }

            chunks = @arr.chunk( 3 )
            chunks.size.should == 3

            chunks[0].size.should == 17
            chunks[1].size.should == 17
            chunks[2].size.should == 16
        end

        context 'when called without params' do
            it 'should split the array into 2 chunks' do
                chunks = @arr.chunk
                chunks.size.should == 2

                24.times do |i|
                    chunks.first[i].should == i
                    chunks.last[i].should  == i + 25
                end
            end
        end
    end

end
