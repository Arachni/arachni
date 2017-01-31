require 'spec_helper'

describe Arachni::BrowserCluster::Jobs::DOMExploration do
    before { @cluster = Arachni::BrowserCluster.new }

    let(:url) do
        Arachni::Utilities.normalize_url( web_server_url_for( :browser ) ) + 'explore'
    end
    after do
        @cluster.shutdown
    end

    def test( job )
        pages = []
        has_event_triggers = false

        @cluster.queue( job ) do |result|
            expect(result).to be_kind_of described_class::Result

            if result.job.is_a? described_class::EventTrigger
                has_event_triggers = true
                expect(result.job.forwarder).to be_kind_of described_class
            end

            pages << result.page
        end
        @cluster.wait

        expect(has_event_triggers).to be_truthy
        browser_explore_check_pages pages
    end

    context 'when the resource is a' do
        context 'String' do
            it 'loads the URL and explores the DOM' do
                test described_class.new( resource: url )
            end
        end

        context 'Arachni::HTTP::Response' do
            subject do
                described_class.new(
                    resource: Arachni::HTTP::Client.get( url, mode: :sync )
                )
            end

            it 'loads it and explores the DOM' do
                test subject
            end

            it "can be stored to disk by the #{Arachni::Support::Database::Queue}" do
                q = Arachni::Support::Database::Queue.new
                q.max_buffer_size = 0

                q << subject

                restored = q.pop
                expect(restored).to eq(subject)
            end
        end

        context 'Arachni::Page' do
            let(:page) { Arachni::Page.from_url( url ) }
            subject { described_class.new( resource: page ) }

            it 'only stores the DOM' do
                expect(subject.resource).to eq page.dom
            end

            it 'loads it and explores the DOM' do
                test subject
            end

            it "can be stored to disk by the #{Arachni::Support::Database::Queue}" do
                q = Arachni::Support::Database::Queue.new
                q.max_buffer_size = 0

                q << subject

                restored = q.pop
                expect(restored).to eq(subject)
            end
        end
    end
end
