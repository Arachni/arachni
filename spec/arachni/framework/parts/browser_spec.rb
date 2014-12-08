require 'spec_helper'

describe Arachni::Framework::Parts::Browser do
    include_examples 'framework'

    describe '#browser_cluster' do
        it "returns #{Arachni::BrowserCluster}" do
            subject.browser_cluster.should be_kind_of Arachni::BrowserCluster
        end

        context "when #{Arachni::OptionGroups::BrowserCluster}#pool_size" do
            it 'returns nil' do
                subject.options.browser_cluster.pool_size = 0
                subject.browser_cluster.should be_nil
            end
        end

        context "when #{Arachni::OptionGroups::Scope}#dom_depth_limit" do
            it 'returns nil' do
                subject.options.scope.dom_depth_limit = 0
                subject.browser_cluster.should be_nil
            end
        end
    end

end
