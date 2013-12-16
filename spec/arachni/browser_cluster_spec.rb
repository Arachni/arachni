require 'spec_helper'

describe Arachni::BrowserCluster do

    let(:url) { Arachni::Utilities.normalize_url( web_server_url_for( :browser ) ) }
    let(:page) { Arachni::HTTP::Client.get( url + 'explore', mode: :sync ).to_page }

    after( :each ) do
        @cluster.shutdown if @cluster
        Arachni::Options.reset

        if ::EM.reactor_running?
            ::EM.stop
            sleep 0.1 while ::EM.reactor_running?
        end
    end

    def find_page_with_form_with_input( pages, input_name )
        pages.find do |page|
            page.forms.find { |form| form.inputs.include? input_name }
        end
    end

    def pages_should_have_form_with_input( pages, input_name )
        find_page_with_form_with_input( pages, input_name ).should be_true
    end

    describe '#initialize' do
        describe :handler do
            it 'sets a proc to handle each page' do
                pages = []
                @cluster = described_class.new(
                    handler: proc do |page|
                        pages << page
                    end
                )

                @cluster.analyze page
                @cluster.wait

                pages_should_have_form_with_input pages, 'by-ajax'
                pages_should_have_form_with_input pages, 'from-post-ajax'
                pages_should_have_form_with_input pages, 'ajax-token'
                pages_should_have_form_with_input pages, 'href-post-name'
            end
        end

        describe :pool_size do
            it 'sets the amount of browsers to instantiate' do
                @cluster = described_class.new(
                    pool_size: 3,
                    handler:   proc {}
                )

                browsers = @cluster.instance_variable_get( :@browsers )
                (browsers[:idle].size + browsers[:busy].size).should == 3
            end

            it 'defaults to 6' do
                @cluster = described_class.new( handler: proc {} )

                browsers = @cluster.instance_variable_get( :@browsers )
                (browsers[:idle].size + browsers[:busy].size).should == 6
            end
        end

        describe :time_to_live do
            it 'sets how many pages each browser should analyze before it is restarted'
        end
    end

    describe '#analyze' do
        it 'analyzes the page' do
            pages = []
            @cluster = described_class.new(
                handler: proc do |page|
                    pages << page
                end
            )

            @cluster.analyze( page )
            @cluster.wait
            pages.should be_any
        end

        context 'when the cluster has ben shutdown' do
            it 'raises Arachni::BrowserCluster::Error::AlreadyShutdown' do
                cluster = described_class.new(
                    handler: proc do |page|
                        pages << page
                    end
                )

                cluster.shutdown
                expect { cluster.analyze( page ) }.to raise_error Arachni::BrowserCluster::Error::AlreadyShutdown
            end
        end
    end

    describe '#wait' do
        it 'waits until the analysis is complete' do
            pages = []
            @cluster = described_class.new(
                handler: proc do |page|
                    pages << page
                end
            )

            @cluster.analyze page

            pages.should be_empty
            @cluster.done?.should be_false
            @cluster.wait
            @cluster.done?.should be_true
            pages.should be_any
        end

        it 'returns self' do
            @cluster = described_class.new(
                handler: proc do |page|
                    pages << page
                end
            )

            @cluster.wait.should == @cluster
        end

        context 'when the cluster has ben shutdown' do
            it 'raises Arachni::BrowserCluster::Error::AlreadyShutdown' do
                cluster = described_class.new(
                    handler: proc do |page|
                        pages << page
                    end
                )

                cluster.shutdown
                expect { cluster.wait }.to raise_error Arachni::BrowserCluster::Error::AlreadyShutdown
            end
        end
    end

    describe '#done?' do
        context 'while analysis is in progress' do
            it 'returns false' do
                @cluster = described_class.new(
                    handler: proc{}
                )

                @cluster.analyze page
                @cluster.done?.should be_false
            end
        end

        context 'when analysis has completed' do
            it 'returns true' do
                @cluster = described_class.new(
                    handler: proc{}
                )

                @cluster.analyze page
                @cluster.done?.should be_false
                @cluster.wait
                @cluster.done?.should be_true
            end
        end

        context 'when the cluster has ben shutdown' do
            it 'raises Arachni::BrowserCluster::Error::AlreadyShutdown' do
                cluster = described_class.new(
                    handler: proc do |page|
                        pages << page
                    end
                )

                cluster.shutdown
                expect { cluster.done? }.to raise_error Arachni::BrowserCluster::Error::AlreadyShutdown
            end
        end
    end

    describe '#sitemap' do
        it 'returns the sitemap as covered by the browser requests' do
            pages = []
            @cluster = described_class.new(
                handler: proc do |page|
                    pages << page
                end
            )

            @cluster.analyze page
            @cluster.wait

            @cluster.sitemap.should == {
                "#{url}explore" => 200,
                "#{url}post-ajax" => 404,
                "#{url}href-ajax" => 200,
                "#{url}get-ajax?ajax-token=my-token" => 200
            }
        end
    end

end
