require 'spec_helper'

describe Arachni::Support::LookUp::Moolb do
    it_behaves_like 'lookup'

    describe '#initialize' do
        describe ':strategy' do
            it 'sets the strategy for the internal cache' do
                options = {
                    strategy: Arachni::Support::Cache::LeastRecentlyUsed,
                    max_size: 3
                }

                lu = described_class.new( options )

                4.times do |i|
                    lu << i
                end

                expect(lu.include?( 0 )).to be_falsey

                1.upto( 3 ) do |i|
                    expect(lu.include?( i )).to be_truthy
                end
            end
        end
        describe ':max_size' do
            it 'sets the maximum size of the cache' do
                options = { max_size: 3 }

                lu = described_class.new( options )

                40.times do |i|
                    lu << i
                end

                expect(lu.size).to eq(3)
            end
        end
    end
end
