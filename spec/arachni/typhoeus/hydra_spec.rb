require 'spec_helper'

describe Typhoeus::Hydra do

    describe '#max_concurrency' do
        it 'is be accessible' do
            h = Typhoeus::Hydra.new
            expect(h.max_concurrency).to be_truthy
            h.max_concurrency = 10
            expect(h.max_concurrency).to eq(10)
        end
    end

end
