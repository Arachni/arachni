require 'spec_helper'

describe Arachni::BrowserCluster do

    let(:url) { Arachni::Utilities.normalize_url( web_server_url_for( :browser ) ) }
    let(:args) { [] }
    let(:job) do
        Arachni::BrowserCluster::Jobs::DOMExploration.new(
            resource: Arachni::HTTP::Client.get( url + 'explore', mode: :sync ),
            args:     args
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
        it "sets window width to #{Arachni::OptionGroups::BrowserCluster}#screen_width" do
            Arachni::Options.browser_cluster.screen_width = 100

            @cluster = described_class.new
            @cluster.workers.each do |browser|
                browser.load url
                expect(browser.javascript.run('return window.innerWidth')).to eq(100)
            end
        end

        it "sets window height to #{Arachni::OptionGroups::BrowserCluster}#screen_height" do
            Arachni::Options.browser_cluster.screen_height = 200

            @cluster = described_class.new
            @cluster.workers.each do |browser|
                browser.load url
                expect(browser.javascript.run('return window.innerHeight')).to eq(200)
            end
        end

        describe ':pool_size' do
            it 'sets the amount of browsers to instantiate' do
                @cluster = described_class.new( pool_size: 3 )
                expect(@cluster.workers.size).to eq(3)
            end

            it "defaults to #{Arachni::OptionGroups::BrowserCluster}#pool_size" do
                Arachni::Options.browser_cluster.pool_size = 10
                @cluster = described_class.new
                expect(@cluster.workers.size).to eq(10)
            end
        end

        describe ':on_pop' do
            it 'assigns blocks to be passed each poped job' do
                cj = nil
                @cluster = described_class.new(
                    on_pop: proc do |j|
                        cj ||= j
                    end
                )

                @cluster.queue( job ){}
                @cluster.wait

                expect(cj.id).to eq(job.id)
            end
        end

        describe ':on_queue' do
            it 'assigns blocks to be passed each queued job' do
                cj = nil
                @cluster = described_class.new(
                    on_queue: proc do |j|
                        cj ||= j
                    end
                )

                @cluster.queue( job ){}

                expect(cj.id).to eq(job.id)
                @cluster.wait
            end
        end

        describe ':on_job_done' do
            it 'assigns blocks to be passed each finished job' do
                cj = nil
                @cluster = described_class.new(
                    on_job_done: proc do |j|
                        cj ||= j
                    end
                )

                @cluster.queue( job ){}
                @cluster.wait

                expect(cj.id).to eq(job.id)
            end
        end
    end

    describe '.statistics' do
        it 'includes :queued_job_count' do
            @cluster = described_class.new

            current = described_class.statistics[:queued_job_count]
            @cluster.with_browser{}
            @cluster.with_browser{}
            @cluster.with_browser{}

            expect(described_class.statistics[:queued_job_count] - current).to eq 3
        end

        it 'includes :completed_job_count' do
            @cluster = described_class.new

            current = described_class.statistics[:completed_job_count]
            @cluster.with_browser{}
            @cluster.with_browser{}
            @cluster.with_browser{}
            @cluster.wait

            expect(described_class.statistics[:completed_job_count] - current).to eq 3
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

            expect(worker).to be_kind_of described_class::Worker
        end

        context 'when arguments have been provided' do
            it 'passes them to the callback' do
                worker = nil

                @cluster = described_class.new
                aa, bb, cc = nil
                @cluster.with_browser 1, 2, 3 do |browser, a, b, c|
                    worker = browser
                    aa = a
                    bb = b
                    cc = c
                end
                @cluster.wait

                expect(aa).to eq 1
                expect(bb).to eq 2
                expect(cc).to eq 3
                expect(worker).to be_kind_of described_class::Worker
            end
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

            expect(pages.first.body).to include "window._#{@cluster.javascript_token}"
        end
    end

    describe '#pending_job_counter' do
        it 'returns the amount of pending jobs' do
            @cluster = described_class.new
            expect(@cluster.pending_job_counter).to eq(0)

            while_in_progress = []
            @cluster.queue( job ) do
                while_in_progress << @cluster.pending_job_counter
            end
            @cluster.wait

            expect(while_in_progress).to be_any
            while_in_progress.each do |pending_job_counter|
                expect(pending_job_counter).to be > 0
            end

            expect(@cluster.pending_job_counter).to eq(0)
        end
    end

    describe '#queue' do
        it 'processes the job' do
            pages = []
            @cluster = described_class.new

            @cluster.queue( job ) do |result|
                pages << result.page
            end
            @cluster.wait

            browser_explore_check_pages pages
        end

        it 'passes self to the callback' do
            pages = []
            @cluster = described_class.new

            @cluster.queue( job ) do |result, cluster|
                expect(cluster).to eq(@cluster)
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

            expect(results.size).to eq(1)
            result = results.first
            expect(result.my_data).to eq('Some stuff')
            expect(result.job.id).to eq(custom_job.id)
        end

        context 'when a callback argument is given' do
            it 'sets it as a callback' do
                pages = []
                @cluster = described_class.new

                m = proc do |result, cluster|
                    expect(cluster).to eq(@cluster)
                    pages << result.page
                end

                @cluster.queue( job, m )
                @cluster.wait

                browser_explore_check_pages pages
            end
        end

        context 'when Job#args have been set' do
            let(:args) { [1, 2] }

            it 'passes them to the callback' do
                pages = []
                @cluster = described_class.new

                @cluster.queue( job ) do |result, a, b|
                    expect(a).to eq args[0]
                    expect(b).to eq args[1]

                    pages << result.page
                end
                @cluster.wait

                browser_explore_check_pages pages
            end
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
                        expect(result.job.never_ending?).to be_truthy
                        pages << result.page
                    end
                    @cluster.wait
                    browser_explore_check_pages pages

                    pages = []
                    @cluster.queue( job ) do |result|
                        expect(result.job.never_ending?).to be_truthy
                        pages << result.page
                    end
                    @cluster.wait
                    expect(pages).to be_empty
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

        context 'when a callback argument is given' do
            it 'sets it as a callback' do
                pages = []
                m = proc do |result|
                    pages << result.page
                end

                @cluster.explore( url, {}, m )
                @cluster.wait

                browser_explore_check_pages pages
            end
        end

        context 'when the resource is a' do
            context 'String' do
                it 'loads the URL and explores the DOM' do
                    pages = []

                    @cluster.explore( url ) do |result|
                        pages << result.page
                    end
                    @cluster.wait

                    browser_explore_check_pages pages
                end
            end

            context 'Arachni::HTTP::Response' do
                it 'loads it and explores the DOM' do
                    pages = []

                    @cluster.explore( Arachni::HTTP::Client.get( url, mode: :sync ) ) do |result|
                        pages << result.page
                    end
                    @cluster.wait

                    browser_explore_check_pages pages
                end
            end

            context 'Arachni::Page' do
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

            context 'when a callback argument is given' do
                it 'sets it as a callback' do
                    pages = []
                    m = proc do |result|
                        pages << result.page
                    end

                    @cluster.trace_taint( url, { taint: taint }, m )
                    @cluster.wait

                    browser_cluster_job_taint_tracer_data_flow_check_pages  pages
                end
            end

            context 'and the resource is a' do
                context 'String' do
                    it 'loads the URL and traces the taint' do
                        pages = []
                        @cluster.trace_taint( url, taint: taint ) do |result|
                            pages << result.page
                        end
                        @cluster.wait

                        browser_cluster_job_taint_tracer_data_flow_check_pages  pages
                    end
                end

                context 'Arachni::HTTP::Response' do
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

                context 'Arachni::Page' do
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
                    context 'String' do
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

                    context 'Arachni::HTTP::Response' do
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

                    context 'Arachni::Page' do
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
                context 'String' do
                    it 'loads the URL and traces the taint' do
                        pages = []
                        @cluster.trace_taint( url ) do |result|
                            pages << result.page
                        end
                        @cluster.wait

                        browser_cluster_job_taint_tracer_execution_flow_check_pages pages
                    end
                end

                context 'Arachni::HTTP::Response' do
                    it 'loads it and traces the taint' do
                        pages = []
                        @cluster.trace_taint( Arachni::HTTP::Client.get( url, mode: :sync ) ) do |result|
                            pages << result.page
                        end
                        @cluster.wait

                        browser_cluster_job_taint_tracer_execution_flow_check_pages pages
                    end
                end

                context 'Arachni::Page' do
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

            expect(calls).to be > 1
            expect(@cluster.job_done?( job )).to eq(true)
        end

        it 'gets called after each job is done' do
            @cluster = described_class.new

            expect(@cluster).to receive(:job_done).with(job)

            q = Queue.new
            @cluster.queue( job ){ q << nil }
            q.pop
        end

        it 'increments the .completed_job_count' do
            pre = described_class.completed_job_count

            @cluster = described_class.new
            @cluster.queue( job ){}
            @cluster.wait

            expect(described_class.completed_job_count).to be > pre
        end

        it 'adds the job time to the .total_job_time' do
            pre = described_class.total_job_time

            @cluster = described_class.new
            @cluster.queue( job ){}
            @cluster.wait

            expect(described_class.total_job_time).to be > pre
        end
    end

    describe '#job_done?' do
        context 'when a job has finished' do
            it 'returns true' do
                @cluster = described_class.new
                @cluster.queue( job ) {}
                @cluster.wait

                expect(@cluster.job_done?( job )).to eq(true)
            end
        end

        context 'when a job is in progress' do
            it 'returns false' do
                @cluster = described_class.new
                @cluster.queue( job ) { }

                expect(@cluster.job_done?( job )).to eq(false)
            end
        end

        context 'when a job has been marked as #never_ending' do
            it 'returns false' do
                @cluster = described_class.new

                job.never_ending = true
                @cluster.queue( job ) {}
                @cluster.wait

                expect(@cluster.job_done?( job )).to eq(false)
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

            expect(pages).to be_empty
            expect(@cluster.done?).to be_falsey
            @cluster.wait
            expect(@cluster.done?).to be_truthy
            expect(pages).to be_any
        end

        it 'returns self' do
            @cluster = described_class.new
            expect(@cluster.wait).to eq(@cluster)
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
                expect(@cluster.done?).to be_falsey
            end
        end

        context 'when analysis has completed' do
            it 'returns true' do
                @cluster = described_class.new
                @cluster.queue( job ) {}
                expect(@cluster.done?).to be_falsey
                @cluster.wait
                expect(@cluster.done?).to be_truthy
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

end
