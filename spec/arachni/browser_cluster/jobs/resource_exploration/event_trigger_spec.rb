require 'spec_helper'

describe Arachni::BrowserCluster::Jobs::DOMExploration::EventTrigger do
    before do
        @cluster = Arachni::BrowserCluster.new

        browser = Arachni::Browser.new
        browser.load url

        browser.each_element_with_events { |element, _| @element = element }
        browser.shutdown
    end

    let(:url) do
        Arachni::Utilities.normalize_url( web_server_url_for( :event_trigger ) )
    end
    let(:event) { :click }
    let(:element) { @element }

    after do
        @cluster.shutdown
    end

    def test( job )
        pages = []

        @cluster.queue( job ) do |result|
            expect(result).to be_kind_of described_class::Result
            pages << result.page
        end
        @cluster.wait

        expect(pages.size).to eq(2)

        page = pages.last
        expect(page.dom.transitions.last.event).to eq(event)
        expect(Nokogiri::HTML( page.body ).xpath("//div[@id='my-div']").first.to_s).to eq(
            '<div id="my-div"><a href="#3">My link</a></div>'
        )
    end

    context 'when the resource is a' do
        context 'String' do
            it 'loads the URL and triggers the given event on the given element' do
                test described_class.new( resource: url, event: event, element: element )
            end
        end

        context 'Arachni::HTTP::Response' do
            it 'loads it and triggers the given event on the given element' do
                test described_class.new(
                         resource: Arachni::HTTP::Client.get( url, mode: :sync ),
                         event:    event,
                         element:  element
                     )
            end
        end

        context 'Arachni::Page' do
            it 'loads it and triggers the given event on the given element' do
                test described_class.new(
                    resource: Arachni::Page.from_url( url ),
                    event:    event,
                    element:  element
                )
            end
        end
    end
end
