require 'spec_helper'

describe Arachni::Issue::Severity::Base do
    describe '#to_sym' do
        it 'returns the severity as a Symbol' do
            described_class.new( 'test' ).to_sym == :test
        end
    end

    describe '#to_s' do
        it 'returns the severity as a String' do
            described_class.new( :test ).to_s == 'test'
        end
    end
end
