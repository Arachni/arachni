require 'spec_helper'

describe Arachni::Element::Capabilities::WithScope::Scope do

    before :each do
        Arachni::Options.reset
    end

    subject { Arachni::Element::Base.new( url: 'http://stuff/' ).scope }

    describe '#out?' do
        it 'returns false' do
            subject.should_not be_out
        end

        context 'when #redundant?' do
            context 'is true' do
                it 'returns true' do
                    subject.stub(:redundant?) { true }
                    subject.should be_out
                end
            end
        end
    end
end
