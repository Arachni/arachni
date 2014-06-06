require 'spec_helper'

describe Arachni::Page::Scope do

    before :each do
        Arachni::Options.reset
    end

    let(:scope){ Arachni::Options.scope }
    let(:page) { Factory[:page] }
    subject { page.scope }

    describe '#exclude?' do
        it 'returns false' do
            subject.exclude?.should be_false
        end

        context 'when the page DOM depth limit has not been exceeded' do
            it 'returns false' do
                scope.dom_depth_limit = 2
                page.dom.stub(:depth) { 1 }
                subject.exclude?.should be_false
            end
        end

        context 'when the page DOM depth limit has been exceeded' do
            it 'returns true' do
                scope.dom_depth_limit = 2
                page.dom.stub(:depth) { 3 }

                subject.exclude?.should be_true
            end
        end
    end

end
