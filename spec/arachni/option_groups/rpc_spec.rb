require 'spec_helper'

describe Arachni::OptionGroups::RPC do
    include_examples 'option_group'
    subject { described_class.new }

    %w(server_socket server_address server_port ssl_ca server_ssl_private_key
        server_ssl_certificate client_ssl_private_key client_ssl_certificate
        client_max_retries).each do |method|
        it { is_expected.to respond_to method }
        it { is_expected.to respond_to "#{method}=" }
    end
end
