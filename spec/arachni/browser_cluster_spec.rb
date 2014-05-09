require 'spec_helper'

describe Arachni::BrowserCluster do

    let(:url) { Arachni::Utilities.normalize_url( web_server_url_for( :browser ) ) }
    let(:job) do
        Arachni::BrowserCluster::Jobs::ResourceExploration.new(
            resource: Arachni::HTTP::Client.get( url + 'explore', mode: :sync )
        )
    end
    let(:custom_job) { Factory[:custom_job] }

    before :each do
        Arachni::Options.reset
    end
    after( :each ) do
        @cluster.shutdown if @cluster
    end

    describe '#initialize' do
        describe :pool_size do
            it 'sets the amount of browsers to instantiate' do
                @cluster = described_class.new( pool_size: 3 )
                @cluster.workers.size.should == 3
            end

            it "defaults to #{Arachni::OptionGroups::BrowserCluster}#pool_size" do
                Arachni::Options.browser_cluster.pool_size = 10
                @cluster = described_class.new
                @cluster.workers.size.should == 10
            end
        end
    end

    describe '#with_browser' do
        it 'provides a worker to the block' do
            worker = nil

            @cluster = described_class.new
            @cluster.with_browser do |browser|
                worker = browser
            end
            @cluster.wait

            worker.should be_kind_of described_class::Worker
        end
    end

    describe '#javascript_token' do
        it 'returns the Javascript token used to namespace the custom JS environment' do
            pages = []
            @cluster = described_class.new

            @cluster.queue( job ) do |result|
                pages << result.page
            end
            @cluster.wait

            pages.first.body.should include "window._#{@cluster.javascript_token}"
        end
    end

    describe '#pending_job_counter' do
        it 'returns the amount of pending jobs' do
            @cluster = described_class.new
            @cluster.pending_job_counter.should == 0

            while_in_progress = []
            @cluster.queue( job ) do
                while_in_progress << @cluster.pending_job_counter
            end
            @cluster.wait

            while_in_progress.should be_any
            while_in_progress.each do |pending_job_counter|
                pending_job_counter.should > 0
            end

            @cluster.pending_job_counter.should == 0
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

            browser_explore_check_pages pages
        end

        it 'supports custom jobs' do
            results = []

            # We need to introduce the custom Job into the parent namespace
            # prior to the BrowserCluster initialization, in order for it to be
            # available in the Peers' namespace.
            custom_job

            @cluster = described_class.new

            @cluster.queue( custom_job ) do |result|
                results << result
            end
            @cluster.wait

            results.size.should == 1
            result = results.first
            result.my_data.should == 'Some stuff'
            result.job.id.should == custom_job.id
        end

        context 'when no callback has been provided' do
            it 'raises ArgumentError' do
                @cluster = described_class.new
                expect { @cluster.queue( job ) }.to raise_error ArgumentError
            end
        end

        context 'when the job has been marked as done' do
            it "raises #{described_class::Job::Error::AlreadyDone}" do
                @cluster = described_class.new
                @cluster.queue( job ){}
                @cluster.job_done( job )
                expect { @cluster.queue( job ){} }.to raise_error described_class::Job::Error::AlreadyDone
            end

            context 'and the job is marked as #never_ending' do
                it 'preserves the analysis state between calls' do
                    pages = []
                    @cluster = described_class.new

                    job.never_ending = true
                    @cluster.queue( job ) do |result|
                        result.job.never_ending?.should be_true
                        pages << result.page
                    end
                    @cluster.wait
                    browser_explore_check_pages pages

                    pages = []
                    @cluster.queue( job ) do |result|
                        result.job.never_ending?.should be_true
                        pages << result.page
                    end
                    @cluster.wait
                    pages.should be_empty
                end
            end
        end

        context 'when the cluster has ben shutdown' do
            it "raises #{described_class::Error::AlreadyShutdown}" do
                cluster = described_class.new
                cluster.shutdown
                expect { cluster.queue( job ){} }.to raise_error described_class::Error::AlreadyShutdown
            end
        end
    end

    describe '#explore' do
        before(:each) { @cluster = described_class.new }
        let(:url) do
            Arachni::Utilities.normalize_url( web_server_url_for( :browser ) ) + 'explore'
        end

        context 'when the resource is a' do
            context String do
                it 'loads the URL and explores the DOM' do
                    pages = []

                    @cluster.explore( url ) do |result|
                        pages << result.page
                    end
                    @cluster.wait

                    browser_explore_check_pages pages
                end
            end

            context Arachni::HTTP::Response do
                it 'loads it and explores the DOM' do
                    pages = []

                    @cluster.explore( Arachni::HTTP::Client.get( url, mode: :sync ) ) do |result|
                        pages << result.page
                    end
                    @cluster.wait

                    browser_explore_check_pages pages
                end
            end

            context Arachni::Page do
                it 'loads it and explores the DOM' do
                    pages = []

                    @cluster.explore( Arachni::Page.from_url( url ) ) do |result|
                        pages << result.page
                    end
                    @cluster.wait

                    browser_explore_check_pages pages
                end
            end
        end
    end

    describe '#trace_taint' do
        before(:each) { @cluster = described_class.new }

        context 'when tracing the data-flow' do
            let(:taint) { Arachni::Utilities.generate_token }
            let(:url) do
                Arachni::Utilities.normalize_url( web_server_url_for( :taint_tracer ) ) +
                    "/data_trace/user-defined-global-functions?taint=#{taint}"
            end

            context 'and the resource is a' do
                context String do
                    it 'loads the URL and traces the taint' do
                        pages = []
                        @cluster.trace_taint( url, taint: taint ) do |result|
                            pages << result.page
                        end
                        @cluster.wait

                        browser_cluster_job_taint_tracer_data_flow_check_pages  pages
                    end
                end

                context Arachni::HTTP::Response do
                    it 'loads it and traces the taint' do
                        pages = []

                        @cluster.trace_taint( Arachni::HTTP::Client.get( url, mode: :sync ),
                                              taint: taint ) do |result|
                            pages << result.page
                        end
                        @cluster.wait

                        browser_cluster_job_taint_tracer_data_flow_check_pages  pages
                    end
                end

                context Arachni::Page do
                    it 'loads it and traces the taint' do
                        pages = []

                        @cluster.trace_taint( Arachni::Page.from_url( url ),
                                              taint: taint ) do |result|
                            pages << result.page
                        end
                        @cluster.wait

                        browser_cluster_job_taint_tracer_data_flow_check_pages  pages
                    end
                end
            end

            context 'and requires a custom taint injector' do
                let(:injector) { "location.hash = #{taint.inspect}" }
                let(:url) do
                    Arachni::Utilities.normalize_url( web_server_url_for( :taint_tracer ) ) +
                        'needs-injector'
                end

                context 'and the resource is a' do
                    context String do
                        it 'loads the URL and traces the taint' do
                            pages = []
                            @cluster.trace_taint( url,
                                                  taint: taint,
                                                  injector: injector ) do |result|
                                pages << result.page
                            end
                            @cluster.wait

                            browser_cluster_job_taint_tracer_data_flow_with_injector_check_pages  pages
                        end
                    end

                    context Arachni::HTTP::Response do
                        it 'loads it and traces the taint' do
                            pages = []
                            @cluster.trace_taint( Arachni::HTTP::Client.get( url, mode: :sync ),
                                                  taint: taint,
                                                  injector: injector ) do |result|
                                pages << result.page
                            end
                            @cluster.wait

                            browser_cluster_job_taint_tracer_data_flow_with_injector_check_pages  pages
                        end
                    end

                    context Arachni::Page do
                        it 'loads it and traces the taint' do
                            pages = []
                            @cluster.trace_taint( Arachni::Page.from_url( url ),
                                                  taint: taint,
                                                  injector: injector ) do |result|
                                pages << result.page
                            end
                            @cluster.wait

                            browser_cluster_job_taint_tracer_data_flow_with_injector_check_pages  pages
                        end
                    end
                end
            end
        end

        context 'when tracing the execution-flow' do
            let(:url) do
                Arachni::Utilities.normalize_url( web_server_url_for( :taint_tracer ) ) +
                    "debug?input=_#{@cluster.javascript_token}TaintTracer.log_execution_flow_sink()"
            end

            context 'and the resource is a' do
                context String do
                    it 'loads the URL and traces the taint' do
                        pages = []
                        @cluster.trace_taint( url ) do |result|
                            pages << result.page
                        end
                        @cluster.wait

                        browser_cluster_job_taint_tracer_execution_flow_check_pages pages
                    end
                end

                context Arachni::HTTP::Response do
                    it 'loads it and traces the taint' do
                        pages = []
                        @cluster.trace_taint( Arachni::HTTP::Client.get( url, mode: :sync ) ) do |result|
                            pages << result.page
                        end
                        @cluster.wait

                        browser_cluster_job_taint_tracer_execution_flow_check_pages pages
                    end
                end

                context Arachni::Page do
                    it 'loads it and traces the taint' do
                        pages = []
                        @cluster.trace_taint( Arachni::Page.from_url( url ) ) do |result|
                            pages << result.page
                        end
                        @cluster.wait

                        browser_cluster_job_taint_tracer_execution_flow_check_pages pages
                    end
                end
            end
        end
    end

    describe '#job_done' do
        it 'marks the given job as done' do
            calls = 0
            @cluster = described_class.new
            @cluster.queue( job ) do
                calls += 1
            end
            @cluster.wait

            calls.should > 1

            @cluster.shutdown

            calls = 0
            @cluster = described_class.new
            @cluster.queue( job ) do
                @cluster.job_done( job )
                calls += 1
            end
            @cluster.wait

            calls.should == 1
        end

        it 'returns true' do
            return_val = nil

            @cluster = described_class.new
            @cluster.queue( job ) do
                return_val = @cluster.job_done( job )
            end
            @cluster.wait

            return_val.should == true
        end
    end

    describe '#job_done?' do
        context 'when a job has finished' do
            it 'returns true' do
                @cluster = described_class.new
                @cluster.queue( job ) {}
                @cluster.wait

                @cluster.job_done?( job ).should == true
            end
        end

        context 'when a job is in progress' do
            it 'returns false' do
                @cluster = described_class.new
                @cluster.queue( job ) { }

                @cluster.job_done?( job ).should == false
            end
        end

        context 'when a job has been marked as #never_ending' do
            it 'returns false' do
                @cluster = described_class.new

                job.never_ending = true
                @cluster.queue( job ) {}
                @cluster.wait

                @cluster.job_done?( job ).should == false
            end
        end

        context 'when a job has been marked as done' do
            it 'returns true' do
                @cluster = described_class.new
                @cluster.job_done( job )
                @cluster.job_done?( job ).should == true
            end
        end

        context 'when the job has not been queued' do
            it "raises #{described_class::Error::JobNotFound}" do
                @cluster = described_class.new
                expect { @cluster.job_done?( job ) }.to raise_error described_class::Error::JobNotFound
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
            it "raises #{described_class::Error::AlreadyShutdown}" do
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
            it "raises #{described_class::Error::AlreadyShutdown}" do
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
