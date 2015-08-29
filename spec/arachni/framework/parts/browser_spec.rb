require 'spec_helper'

describe Arachni::Framework::Parts::Browser do
    include_examples 'framework'

    describe '#browser_cluster' do
        context 'when #use_browsers? is' do
            context 'true' do
                before do
                    allow(subject).to receive(:use_browsers?) { true }
                end

                it "returns #{Arachni::BrowserCluster}" do
                    expect(subject.browser_cluster).to be_kind_of Arachni::BrowserCluster
                end
            end

            context 'false' do
                before do
                    allow(subject).to receive(:use_browsers?) { false }
                end

                it 'returns nil' do
                    expect(subject.browser_cluster).to be_nil
                end
            end
        end
    end

    describe '#use_browsers?' do
        context "when #{Arachni::OptionGroups::BrowserCluster}#pool_size is" do
            context '0' do
                before do
                    subject.options.browser_cluster.pool_size = 0
                end

                it 'returns false' do
                    expect(subject.use_browsers?).to be_falsey
                end
            end

            context '> 0' do
                before do
                    subject.options.browser_cluster.pool_size = 1
                end

                it 'returns true' do
                    expect(subject.use_browsers?).to be_truthy
                end
            end
        end

        context "when #{Arachni::OptionGroups::Scope}#dom_depth_limit is" do
            context '0' do
                before do
                    subject.options.scope.dom_depth_limit = 0
                end

                it 'returns false' do
                    expect(subject.use_browsers?).to be_falsey
                end
            end

            context '> 0' do
                before do
                    subject.options.scope.dom_depth_limit = 1
                end

                it 'returns true' do
                    expect(subject.use_browsers?).to be_truthy
                end
            end
        end

        context 'when #host_has_browser? is' do
            context 'true' do
                before do
                    allow(subject).to receive(:use_browsers?) { true }
                end

                it 'returns true' do
                    expect(subject.use_browsers?).to be_truthy
                end
            end

            context 'false' do
                before do
                    allow(subject).to receive(:host_has_browser?) { false }
                end

                it 'returns false' do
                    expect(subject.use_browsers?).to be_falsey
                end
            end
        end
    end

    describe '#host_has_browser?' do
        context "when #{Arachni::Browser}.has_executable? is" do
            context 'true' do
                before do
                    allow(Arachni::Browser).to receive(:has_executable?) { true }
                end

                it 'returns true' do
                    expect(subject.host_has_browser?).to be_truthy
                end
            end

            context 'false' do
                before do
                    allow(Arachni::Browser).to receive(:has_executable?) { false }
                end

                it 'returns false' do
                    expect(subject.host_has_browser?).to be_falsey
                end
            end
        end
    end
end
