require 'spec_helper'

describe Arachni::Page::Scope do

    before :each do
        Arachni::Options.reset
    end

    let(:scope){ Arachni::Options.scope }
    let(:page) { Factory[:page] }
    subject { page.scope }

    describe '#out?' do
        it 'returns false' do
            subject.out?.should be_false
        end

        context "when #{Arachni::HTTP::Response::Scope}#out?" do
            context true do
                it 'returns true' do
                    # We can't stub #out? because we also override it.
                    Arachni::HTTP::Response::Scope.any_instance.stub(:exclude?) { true }
                    subject.out?.should be_true
                end
            end

            context false do
                it 'returns false' do
                    Arachni::HTTP::Response::Scope.any_instance.stub(:exclude?) { false }
                    subject.out?.should be_false
                end
            end
        end

        context 'when #dom_depth_limit_reached?' do
            context true do
                it 'returns true' do
                    subject.stub(:dom_depth_limit_reached?) { true }
                    subject.out?.should be_true
                end
            end

            context false do
                it 'returns false' do
                    subject.stub(:dom_depth_limit_reached?) { false }
                    subject.out?.should be_false
                end
            end
        end
    end

    describe '#dom_depth_limit_reached?' do
        context "when #{Arachni::OptionGroups::Scope}#dom_depth_limit has" do
            context 'been exceeded' do
                it 'returns true' do
                    scope.dom_depth_limit = 2
                    page.dom.stub(:depth) { 3 }

                    subject.dom_depth_limit_reached?.should be_true
                end
            end

            context 'not been exceeded' do
                it 'returns false' do
                    scope.dom_depth_limit = 2
                    page.dom.stub(:depth) { 1 }
                    subject.dom_depth_limit_reached?.should be_false
                end
            end

            context 'not been set' do
                it 'returns false' do
                    page.dom.stub(:depth) { 3 }
                    subject.dom_depth_limit_reached?.should be_false
                end
            end
        end
    end

end
