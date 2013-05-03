require 'spec_helper'

describe Typhoeus::Hydra do

    describe '#max_concurrency' do
        it 'is be accessible' do
            h = Typhoeus::Hydra.new
            h.max_concurrency.should be_true
            h.max_concurrency = 10
            h.max_concurrency.should == 10
        end
    end

end
