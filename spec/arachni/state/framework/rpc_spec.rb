require 'spec_helper'

describe Arachni::State::Framework::RPC do
    subject { described_class.new }
    before(:each) { subject.clear }

    let(:page) { Factory[:page] }

    describe '#distributed_pages' do
        it "returns an instance of #{Arachni::Support::LookUp::HashSet}" do
            subject.distributed_pages.should be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#distributed_elements' do
        it "returns an instance of #{Set}" do
            subject.distributed_elements.should be_kind_of Set
        end
    end

    describe '#distributed_page_queue' do
        it "returns an instance of #{Arachni::Support::Database::Queue}" do
            subject.distributed_page_queue.should be_kind_of Arachni::Support::Database::Queue
        end
    end

    describe '#clear' do
        %w(distributed_pages distributed_elements distributed_page_queue).each do |method|
            it "clears ##{method}" do
                subject.send(method).should receive(:clear)
                subject.clear
            end
        end
    end
end
