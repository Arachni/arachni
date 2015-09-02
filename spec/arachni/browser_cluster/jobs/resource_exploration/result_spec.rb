require 'spec_helper'

describe Arachni::BrowserCluster::Jobs::DOMExploration::Result do
    subject { described_class.new }
    it { is_expected.to respond_to :page }
    it { is_expected.to respond_to :page= }
end
