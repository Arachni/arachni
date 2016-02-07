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
            expect(subject.out?).to be_falsey
        end

        context "when #{Arachni::HTTP::Response::Scope}#out?" do
            context 'true' do
                it 'returns true' do
                    # We can't stub #out? because we also override it.
                    allow_any_instance_of(Arachni::HTTP::Response::Scope).to receive(:exclude?) { true }
                    expect(subject.out?).to be_truthy
                end
            end

            context 'false' do
                it 'returns false' do
                    allow_any_instance_of(Arachni::HTTP::Response::Scope).to receive(:exclude?) { false }
                    expect(subject.out?).to be_falsey
                end
            end
        end

        context 'when #dom_depth_limit_reached?' do
            context 'true' do
                it 'returns true' do
                    allow(subject).to receive(:dom_depth_limit_reached?) { true }
                    expect(subject.out?).to be_truthy
                end
            end

            context 'false' do
                it 'returns false' do
                    allow(subject).to receive(:dom_depth_limit_reached?) { false }
                    expect(subject.out?).to be_falsey
                end
            end
        end
    end

    describe '#dom_depth_limit_reached?' do
        context "when #{Arachni::OptionGroups::Scope}#dom_depth_limit has" do
            context 'been exceeded' do
                it 'returns true' do
                    scope.dom_depth_limit = 2
                    allow(page.dom).to receive(:depth) { 3 }

                    expect(subject.dom_depth_limit_reached?).to be_truthy
                end
            end

            context 'not been exceeded' do
                it 'returns false' do
                    scope.dom_depth_limit = 2
                    allow(page.dom).to receive(:depth) { 1 }
                    expect(subject.dom_depth_limit_reached?).to be_falsey
                end
            end

            context 'not been set' do
                it 'returns false' do
                    allow(page.dom).to receive(:depth) { 3 }
                    expect(subject.dom_depth_limit_reached?).to be_falsey
                end
            end
        end
    end

end
