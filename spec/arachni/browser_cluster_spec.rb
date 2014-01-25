require 'spec_helper'

class MyJob < Arachni::BrowserCluster::Job
    class Result < Arachni::BrowserCluster::Job::Result
        attr_accessor :my_data
    end

    def run
        save_result my_data: 'Some stuff'
    end
end

describe Arachni::BrowserCluster do

    let(:url) { Arachni::Utilities.normalize_url( web_server_url_for( :browser ) ) }
    let(:job) do
        Arachni::BrowserCluster::Jobs::ResourceExploration.new(
            resource: Arachni::HTTP::Client.get( url + 'explore', mode: :sync )
        )
    end

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
        describe :pool_size do
            it 'sets the amount of browsers to instantiate' do
                @cluster = described_class.new( pool_size: 3 )

                browsers = @cluster.instance_variable_get( :@browsers )
                (browsers[:idle].size + browsers[:busy].size).should == 3
            end

            it 'defaults to 6' do
                @cluster = described_class.new
                browsers = @cluster.instance_variable_get( :@browsers )
                (browsers[:idle].size + browsers[:busy].size).should == 6
            end
        end

        describe :time_to_live do
            it 'sets how many pages each browser should analyze before it is restarted'
        end
    end

    describe '#queue' do
        it 'processes the job' do
            pages = []
            @cluster = described_class.new

            @cluster.queue( job ) do |result|
                result.job.id.should == job.id
                pages << result.page
            end
            @cluster.wait

            pages_should_have_form_with_input pages, 'by-ajax'
            pages_should_have_form_with_input pages, 'from-post-ajax'
            pages_should_have_form_with_input pages, 'ajax-token'
            pages_should_have_form_with_input pages, 'href-post-name'
        end

        it 'supports custom jobs' do
            results = []
            @cluster = described_class.new

            job = MyJob.new
            @cluster.queue( job ) do |result|
                results << result
            end
            @cluster.wait

            results.size.should == 1
            result = results.first
            result.my_data.should == 'Some stuff'
            result.job.id.should == job.id
        end

        context 'when no callback has been provided' do
            it 'raises ArgumentError' do
                @cluster = described_class.new
                expect { @cluster.queue( job ) }.to raise_error ArgumentError
            end
        end

        context 'when the cluster has ben shutdown' do
            it 'raises Arachni::BrowserCluster::Error::AlreadyShutdown' do
                cluster = described_class.new
                cluster.shutdown
                expect { cluster.queue( job ) }.to raise_error described_class::Error::AlreadyShutdown
            end
        end
    end

    describe '#wait' do
        it 'waits until the analysis is complete' do
            pages = []

            @cluster = described_class.new
            @cluster.queue( job ) do |result|
                pages << result.page
            end

            pages.should be_empty
            @cluster.done?.should be_false
            @cluster.wait
            @cluster.done?.should be_true
            pages.should be_any
        end

        it 'returns self' do
            @cluster = described_class.new
            @cluster.wait.should == @cluster
        end

        context 'when the cluster has ben shutdown' do
            it 'raises Arachni::BrowserCluster::Error::AlreadyShutdown' do
                cluster = described_class.new
                cluster.shutdown
                expect { cluster.wait }.to raise_error described_class::Error::AlreadyShutdown
            end
        end
    end

    describe '#done?' do
        context 'while analysis is in progress' do
            it 'returns false' do
                @cluster = described_class.new
                @cluster.queue( job ) {}
                @cluster.done?.should be_false
            end
        end

        context 'when analysis has completed' do
            it 'returns true' do
                @cluster = described_class.new
                @cluster.queue( job ) {}
                @cluster.done?.should be_false
                @cluster.wait
                @cluster.done?.should be_true
            end
        end

        context 'when the cluster has been shutdown' do
            it 'raises Arachni::BrowserCluster::Error::AlreadyShutdown' do
                cluster = described_class.new
                cluster.shutdown
                expect { cluster.done? }.to raise_error described_class::Error::AlreadyShutdown
            end
        end
    end

    describe '#sitemap' do
        it 'returns the sitemap as covered by the browser jobs' do
            @cluster = described_class.new
            @cluster.queue( job ) {}
            @cluster.wait

            @cluster.sitemap.
                reject { |k, v| k.start_with? Arachni::Browser::Javascript::SCRIPT_BASE_URL }.
                should == {
                    "#{url}explore"   => 200,
                    "#{url}post-ajax" => 404,
                    "#{url}href-ajax" => 200,
                    "#{url}get-ajax?ajax-token=my-token" => 200
                }
        end
    end

end
