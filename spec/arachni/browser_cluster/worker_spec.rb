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
        Arachni::BrowserCluster::Jobs::DOMExploration.new(
            resource: Arachni::HTTP::Client.get( url + 'explore', mode: :sync )
        )
    end
    let(:custom_job) { Factory[:custom_job] }
    let(:sleep_job) { Factory[:sleep_job] }
    let(:subject) { @cluster.workers.first }

    describe '#initialize' do
        describe ':job_timeout' do
            it 'sets how much time to allow each job to run' do
                @worker = described_class.new( job_timeout: 10 )
                expect(@worker.job_timeout).to eq(10)
            end

            it "defaults to #{Arachni::OptionGroups::BrowserCluster}#job_timeout" do
                Arachni::Options.browser_cluster.job_timeout = 5
                @worker = described_class.new
                expect(@worker.job_timeout).to eq(5)
            end
        end

        describe ':max_time_to_live' do
            it 'sets how many jobs should be run before respawning' do
                @worker = described_class.new( max_time_to_live: 10 )
                expect(@worker.max_time_to_live).to eq(10)
            end

            it "defaults to #{Arachni::OptionGroups::BrowserCluster}#worker_time_to_live" do
                Arachni::Options.browser_cluster.worker_time_to_live = 5
                @worker = described_class.new
                expect(@worker.max_time_to_live).to eq(5)
            end
        end
    end

    describe '#run_job' do
        it 'processes jobs from #master' do
            expect(subject).to receive(:run_job).with(custom_job)
            @cluster.queue( custom_job ){}
            @cluster.wait
        end

        it 'assigns #job to the running job' do
            job = nil
            @cluster.queue( custom_job ) do
                job = subject.job
            end
            @cluster.wait
            expect(job).to eq(custom_job)
        end

        context 'before running the job' do
            context 'when PhantomJS is dead' do
                it 'spawns a new one' do
                    Arachni::Processes::Manager.kill subject.browser_pid

                    dead_lifeline_pid = subject.lifeline_pid
                    dead_browser_pid  = subject.browser_pid

                    @cluster.queue( custom_job ){}
                    @cluster.wait

                    expect(subject.browser_pid).not_to eq(dead_browser_pid)
                    expect(subject.lifeline_pid).not_to eq(dead_lifeline_pid)

                    expect(Arachni::Processes::Manager.alive?( subject.lifeline_pid )).to be_truthy
                    expect(Arachni::Processes::Manager.alive?( subject.browser_pid )).to be_truthy
                end
            end

            context 'when the lifeline is dead' do
                it 'spawns a new one' do
                    Arachni::Processes::Manager << subject.browser_pid
                    Arachni::Processes::Manager.kill subject.lifeline_pid

                    dead_lifeline_pid = subject.lifeline_pid
                    dead_browser_pid  = subject.browser_pid

                    @cluster.queue( custom_job ){}
                    @cluster.wait

                    expect(subject.browser_pid).not_to eq(dead_browser_pid)
                    expect(subject.lifeline_pid).not_to eq(dead_lifeline_pid)

                    expect(Arachni::Processes::Manager.alive?( subject.lifeline_pid )).to be_truthy
                    expect(Arachni::Processes::Manager.alive?( subject.browser_pid )).to be_truthy
                end
            end
        end

        context 'when a job fails' do
            it 'ignores it' do
                allow(custom_job).to receive(:configure_and_run){ raise 'stuff' }
                expect(subject.run_job( custom_job )).to be_truthy
            end

            context 'Selenium::WebDriver::Error::WebDriverError' do
                it 'respawns' do
                    expect(custom_job).to receive(:configure_and_run) do
                        raise Selenium::WebDriver::Error::WebDriverError
                    end

                    expect(subject.watir).to receive(:close) do
                        raise Selenium::WebDriver::Error::WebDriverError
                    end

                    watir = subject.watir
                    pid   = subject.browser_pid

                    subject.run_job( custom_job )

                    expect(watir).not_to eq(subject.watir)
                    expect(pid).not_to eq(subject.browser_pid)
                end
            end
        end

        context 'when the job finishes' do
            let(:page) { Arachni::Page.from_url(url) }

            it "clears the #{Arachni::Browser::Javascript}#taint" do
                subject.javascript.taint = 'stuff'

                @cluster.queue( custom_job ) {}
                @cluster.wait

                expect(subject.javascript.taint).to be_nil
            end

            it 'clears #preloads' do
                subject.preload page
                expect(subject.preloads).to be_any

                @cluster.queue( custom_job ) {}
                @cluster.wait

                expect(subject.preloads).to be_empty
            end

            it 'clears #cache' do
                subject.cache page
                expect(subject.cache).to be_any

                @cluster.queue( custom_job ) {}
                @cluster.wait

                expect(subject.cache).to be_empty
            end

            it 'clears #captured_pages' do
                subject.captured_pages << page

                @cluster.queue( custom_job ) {}
                @cluster.wait

                expect(subject.captured_pages).to be_empty
            end

            it 'clears #page_snapshots' do
                subject.page_snapshots << page

                @cluster.queue( custom_job ) {}
                @cluster.wait

                expect(subject.page_snapshots).to be_empty
            end

            it 'clears #page_snapshots_with_sinks' do
                subject.page_snapshots_with_sinks << page

                @cluster.queue( custom_job ) {}
                @cluster.wait

                expect(subject.page_snapshots_with_sinks).to be_empty
            end

            it 'clears #on_new_page callbacks' do
                subject.on_new_page{}

                @cluster.queue( custom_job ) {}
                @cluster.wait

                expect(subject.observer_count_for(:on_new_page)).to eq(0)
            end

            it 'clears #on_new_page_with_sink callbacks' do
                subject.on_new_page_with_sink{}

                @cluster.queue( custom_job ){}
                @cluster.wait

                expect(subject.observer_count_for(:on_new_page_with_sink)).to eq(0)
            end

            it 'clears #on_response callbacks' do
                subject.on_response{}

                @cluster.queue( custom_job ){}
                @cluster.wait

                expect(subject.observer_count_for(:on_response)).to eq(0)
            end

            it 'clears #on_fire_event callbacks' do
                subject.on_fire_event{}

                @cluster.queue( custom_job ){}
                @cluster.wait

                expect(subject.observer_count_for(:on_fire_event)).to eq(0)
            end

            it 'removes #job' do
                @cluster.queue( custom_job ){}
                @cluster.wait
                expect(subject.job).to be_nil
            end

            it 'decrements #time_to_live' do
                @cluster.queue( custom_job ) {}
                @cluster.wait
                expect(subject.time_to_live).to eq(subject.max_time_to_live - 1)
            end

            it 'sets Job#time' do
                @cluster.queue( custom_job ) {}
                @cluster.wait
                expect(custom_job.time).to be > 0
            end

            context 'when #time_to_live reaches 0' do
                it 'respawns the browser' do
                    @cluster.shutdown

                    Arachni::Options.browser_cluster.worker_time_to_live = 1
                    @cluster = Arachni::BrowserCluster.new( pool_size: 1 )

                    subject.max_time_to_live = 1

                    watir         = subject.watir
                    pid = subject.browser_pid

                    @cluster.queue( custom_job ) {}
                    @cluster.wait

                    expect(watir).not_to eq(subject.watir)
                    expect(pid).not_to eq(subject.browser_pid)
                end
            end

            context 'when cookie clearing raises' do
                context 'Selenium::WebDriver::Error::NoSuchWindowError' do
                    it 'respawns' do
                        allow(subject.watir).to receive(:cookies) do
                            raise Selenium::WebDriver::Error::NoSuchWindowError
                        end

                        watir = subject.watir
                        pid   = subject.browser_pid

                        subject.run_job( custom_job )

                        expect(watir).not_to eq(subject.watir)
                        expect(pid).not_to eq(subject.browser_pid)
                    end
                end
            end
        end

        context 'when the job takes more than #job_timeout' do
            before do
                subject.job_timeout = 1
            end

            it 'sets Job#time' do
                @cluster.queue( sleep_job ) {}
                @cluster.wait
                expect(sleep_job.time).to be > 1
                expect(sleep_job.time).to be < 1.1
            end

            it 'sets Job#timed_out?' do
                @cluster.queue( sleep_job ) {}
                @cluster.wait
                expect(sleep_job).to be_timed_out
            end
        end
    end

end
