require 'spec_helper'

describe Arachni::BrowserCluster::Jobs::ResourceExploration do
    before { @cluster = Arachni::BrowserCluster.new }

    let(:url) do
        Arachni::Utilities.normalize_url( web_server_url_for( :browser ) ) + 'explore'
    end
    after do
        @cluster.shutdown if @cluster
        Arachni::Options.reset

        if ::EM.reactor_running?
            ::EM.stop
            sleep 0.1 while ::EM.reactor_running?
        end
    end

    def test( job )
        pages = []
        has_event_triggers = false

        @cluster.queue( job ) do |result|
            result.should be_kind_of described_class::Result

            if result.job.is_a? described_class::EventTrigger
                has_event_triggers = true
                result.job.forwarder.should be_kind_of described_class
            end

            pages << result.page
        end
        @cluster.wait

        has_event_triggers.should be_true
        browser_explore_check_pages pages
    end

    context 'when the resource is a' do
        context String do
            it 'loads the URL and explores the DOM' do
                test described_class.new( resource: url )
            end
        end

        context Arachni::HTTP::Response do
            it 'loads it and explores the DOM' do
                test described_class.new(
                    resource: Arachni::HTTP::Client.get( url, mode: :sync )
                )
            end
        end

        context Arachni::Page do
            it 'loads it and explores the DOM' do
                test described_class.new( resource: Arachni::Page.from_url( url ) )
            end
        end
    end
end
