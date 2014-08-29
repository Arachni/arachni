require 'spec_helper'

describe Arachni::OptionGroups::HTTP do
    include_examples 'option_group'
    subject { described_class.new }

    %w(request_redirect_limit request_concurrency request_queue_size
        request_timeout authentication_username authentication_password
        response_max_size proxy_host proxy_port proxy_username proxy_password
        proxy_type proxy cookies cookie_jar_filepath cookie_string user_agent
        request_headers).each do |method|
        it { should respond_to method }
        it { should respond_to "#{method}=" }
    end

    describe '#user_agent' do
        it "defaults to Arachni/v#{Arachni::VERSION}" do
            subject.user_agent.should == 'Arachni/v' + Arachni::VERSION.to_s
        end
    end

    describe '#request_timeout' do
        it 'defaults to 50000' do
            subject.request_timeout.should == 50000
        end
    end

    describe '#response_max_size' do
        it 'defaults to nil' do
            subject.response_max_size.should be_nil
        end
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it "does not include 'cookie_jar_filepath'" do
            subject.cookie_jar_filepath = 'stuff'
            data.should_not include 'cookie_jar_filepath'
        end
    end
end
