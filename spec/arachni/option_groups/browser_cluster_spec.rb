require 'spec_helper'

describe Arachni::OptionGroups::BrowserCluster do
    include_examples 'option_group'
    subject { described_class.new }

    %w(pool_size job_timeout worker_time_to_live ignore_images screen_width
        screen_height).each do |method|
        it { is_expected.to respond_to method }
        it { is_expected.to respond_to "#{method}=" }
    end
end
