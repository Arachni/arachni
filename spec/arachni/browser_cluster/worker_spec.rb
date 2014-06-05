require 'spec_helper'

class Arachni::BrowserCluster::Worker
    def observer_count_for( event )
        observers_for( event ).size
    end
end

describe Arachni::BrowserCluster::Worker do
    before( :each ) do
        @cluster = Arachni::BrowserCluster.new( pool_size: 1 )
    end
    after( :each ) do
        @cluster.shutdown if @cluster
        @worker.shutdown  if @worker
    end

    let(:url) { Arachni::Utilities.normalize_url( web_server_url_for( :browser ) ) }
    let(:job) do
        Arachni::BrowserCluster::Jobs::ResourceExploration.new(
            resource: Arachni::HTTP::Client.get( url + 'explore', mode: :sync )
        )
    end
    let(:custom_job) { Factory[:custom_job] }
    let(:sleep_job) { Factory[:sleep_job] }
    let(:subject) { @cluster.workers.first }

    describe '#initialize' do
        describe :job_timeout do
            it 'sets how much time to allow each job to run' do
                @worker = described_class.new( job_timeout: 10 )
                @worker.job_timeout.should == 10
            end

            it "defaults to #{Arachni::OptionGroups::BrowserCluster}#job_timeout" do
                Arachni::Options.browser_cluster.job_timeout = 5
                @worker = described_class.new
                @worker.job_timeout.should == 5
            end
        end

        describe :max_time_to_live do
            it 'sets how many jobs should be run before respawning' do
                @worker = described_class.new( max_time_to_live: 10 )
                @worker.max_time_to_live.should == 10
            end

            it "defaults to #{Arachni::OptionGroups::BrowserCluster}#worker_time_to_live" do
                Arachni::Options.browser_cluster.worker_time_to_live = 5
                @worker = described_class.new
                @worker.max_time_to_live.should == 5
            end
        end
    end

    describe '#run_job' do
        it 'processes jobs from #master' do
            subject.should receive(:run_job).with(custom_job)
            @cluster.queue( custom_job ){}
            @cluster.wait
        end

        it 'assigns #job to the running job' do
            job = nil
            @cluster.queue( custom_job ) do
                job = subject.job
            end
            @cluster.wait
            job.should == custom_job
        end

        context 'before running the job' do
            it 'ensures that there is a live PhantomJS process' do
                Arachni::Processes::Manager.kill subject.pid
                expect{ Process.getpgid( subject.pid ) }.to raise_error Errno::ESRCH
                dead_pid = subject.pid

                @cluster.queue( custom_job ){}
                @cluster.wait

                subject.pid.should_not == dead_pid
                Process.getpgid( subject.pid ).should be_true
            end
        end

        context 'when a job fails' do
            it 'ignores it' do
                custom_job.stub(:configure_and_run){ raise 'stuff' }
                subject.run_job( custom_job ).should be_true
            end
        end

        context 'when the job finishes' do
            let(:page) { Arachni::Page.from_url(url) }

            context 'when there are 5 or more windows open' do
                before(:each) do
                    5.times do
                        subject.javascript.run( 'window.open()' )
                    end
                end

                it 'respawns PhantomJS' do
                    watir         = subject.watir
                    pid = subject.pid

                    subject.watir.windows.size.should > 5
                    @cluster.explore( page ) {}
                    @cluster.wait

                    watir.should_not == subject.watir
                    pid.should_not == subject.pid
                    subject.watir.windows.size.should == 2
                end

                it 'clears the cached HTTP responses' do
                    subject.preload page
                    subject.preloads.should be_any
                    subject.instance_variable_get(:@window_responses)

                    subject.watir.windows.size.should > 5
                    @cluster.queue( custom_job ) {}
                    @cluster.wait

                    subject.instance_variable_get(:@window_responses).should be_empty
                end
            end

            it "clears the #{Arachni::Browser::Javascript}#taint" do
                subject.javascript.taint = 'stuff'

                @cluster.queue( custom_job ) {}
                @cluster.wait

                subject.javascript.taint.should be_nil
            end

            it 'clears #cookies' do
                subject.preload page
                subject.preloads.should be_any

                @cluster.with_browser do |browser|
                    browser.load page
                    subject.cookies.should be_any
                end
                @cluster.wait

                subject.cookies.should be_empty
            end

            it 'clears #preloads' do
                subject.preload page
                subject.preloads.should be_any

                @cluster.queue( custom_job ) {}
                @cluster.wait

                subject.preloads.should be_empty
            end

            it 'clears #cache' do
                subject.cache page
                subject.cache.should be_any

                @cluster.queue( custom_job ) {}
                @cluster.wait

                subject.cache.should be_empty
            end

            it 'clears #captured_pages' do
                subject.captured_pages << page

                @cluster.queue( custom_job ) {}
                @cluster.wait

                subject.captured_pages.should be_empty
            end

            it 'clears #page_snapshots' do
                subject.page_snapshots << page

                @cluster.queue( custom_job ) {}
                @cluster.wait

                subject.page_snapshots.should be_empty
            end

            it 'clears #page_snapshots_with_sinks' do
                subject.page_snapshots_with_sinks << page

                @cluster.queue( custom_job ) {}
                @cluster.wait

                subject.page_snapshots_with_sinks.should be_empty
            end

            it 'clears #on_new_page callbacks' do
                subject.on_new_page{}

                @cluster.queue( custom_job ) {}
                @cluster.wait

                subject.observer_count_for(:on_new_page).should == 0
            end

            it 'clears #on_new_page_with_sink callbacks' do
                subject.on_new_page_with_sink{}

                @cluster.queue( custom_job ){}
                @cluster.wait

                subject.observer_count_for(:on_new_page_with_sink).should == 0
            end

            it 'clears #on_response callbacks' do
                subject.on_response{}

                @cluster.queue( custom_job ){}
                @cluster.wait

                subject.observer_count_for(:on_response).should == 0
            end

            it 'clears #on_fire_event callbacks' do
                subject.on_fire_event{}

                @cluster.queue( custom_job ){}
                @cluster.wait

                subject.observer_count_for(:on_fire_event).should == 0
            end

            it 'removes #job' do
                @cluster.queue( custom_job ){}
                @cluster.wait
                subject.job.should be_nil
            end

            it 'decrements #time_to_live' do
                @cluster.queue( custom_job ) {}
                @cluster.wait
                subject.time_to_live.should == subject.max_time_to_live - 1
            end

            context 'when #time_to_live reaches 0' do
                it 'respawns the browser' do
                    @cluster.shutdown

                    Arachni::Options.browser_cluster.worker_time_to_live = 1
                    @cluster = Arachni::BrowserCluster.new( pool_size: 1 )

                    subject.max_time_to_live = 1

                    watir         = subject.watir
                    pid = subject.pid

                    @cluster.queue( custom_job ) {}
                    @cluster.wait

                    watir.should_not == subject.watir
                    pid.should_not == subject.pid
                end
            end

            context "when cookie clearing raises #{Selenium::WebDriver::Error::NoSuchWindowError}" do
                it 'respawns' do
                    subject.watir.stub(:cookies) do
                        raise Selenium::WebDriver::Error::NoSuchWindowError
                    end

                    watir         = subject.watir
                    pid = subject.pid

                    subject.run_job( custom_job )

                    watir.should_not == subject.watir
                    pid.should_not == subject.pid
                end
            end

        end

        context 'when the job takes more than #job_timeout' do
            it 'aborts it' do
                subject.job_timeout = 1
                @cluster.queue( sleep_job ) {}
                @cluster.wait
            end
        end
    end

end
