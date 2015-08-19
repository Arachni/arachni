require 'spec_helper'

describe Arachni::Element::Capabilities::WithScope::Scope do

    before :each do
        Arachni::Options.reset
    end

    subject { Arachni::Element::Base.new( url: 'http://stuff/' ).scope }

    describe '#out?' do
        it 'returns false' do
            expect(subject).not_to be_out
        end

        context 'when #redundant?' do
            context 'is true' do
                it 'returns true' do
                    allow(subject).to receive(:redundant?) { true }
                    expect(subject).to be_out
                end
            end
        end

        context "when #{Arachni::OptionGroups::Audit}#element?" do
            context 'is false' do
                it 'returns true' do
                    allow(Arachni::Options.audit).to receive(:element?) { false }
                    expect(subject).to be_out
                end
            end
        end
    end
end
