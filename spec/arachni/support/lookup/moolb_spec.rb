require 'spec_helper'

describe Arachni::Support::LookUp::Moolb do
    it_behaves_like 'lookup'

    describe '#initialize' do
        describe :strategy do
            it 'sets the strategy for the internal cache' do
                options = {
                    strategy: Arachni::Support::Cache::LeastRecentlyUsed,
                    max_size: 3
                }

                lu = described_class.new( options )

                4.times do |i|
                    lu << i
                end

                lu.include?( 0 ).should be_false

                1.upto( 3 ) do |i|
                    lu.include?( i ).should be_true
                end
            end
        end
        describe :max_size do
            it 'sets the maximum size of the cache' do
                options = { max_size: 3 }

                lu = described_class.new( options )

                40.times do |i|
                    lu << i
                end

                lu.size.should == 3
            end
        end
    end
end
