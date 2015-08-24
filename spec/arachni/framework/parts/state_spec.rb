require 'spec_helper'

describe Arachni::Framework::Parts::State do
    include_examples 'framework'

    describe '#scanning?' do
        it "delegates to #{Arachni::State::Framework}#scanning?" do
            allow(subject.state).to receive(:scanning?) { :stuff }
            expect(subject.scanning?).to eq(:stuff)
        end
    end

    describe '#done?' do
        it "delegates to #{Arachni::State::Framework}#done?" do
            allow(subject.state).to receive(:done?) { :stuff }
            expect(subject.done?).to eq(:stuff)
        end
    end

    describe '#paused?' do
        it "delegates to #{Arachni::State::Framework}#paused?" do
            allow(subject.state).to receive(:paused?) { :stuff }
            expect(subject.paused?).to eq(:stuff)
        end
    end

    describe '#state' do
        it "returns #{Arachni::State::Framework}" do
            expect(subject.state).to be_kind_of Arachni::State::Framework
        end
    end

    describe '#abort' do
        it 'aborts the system' do
            @options.paths.checks  = fixtures_path + '/signature_check/'

            Arachni::Framework.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.plugins.load :wait
                f.checks.load :signature

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while Arachni::Data.issues.size < 2

                f.abort
                t.join

                expect(Arachni::Data.issues.size).to be < 500
            end
        end

        it 'sets #status to :aborted' do
            Arachni::Framework.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links
                f.checks.load :signature

                t = Thread.new do
                    f.run
                end
                sleep 0.1 while f.status != :scanning

                f.abort
                expect(f.status).to eq(:aborted)

                t.join
                expect(f.status).to eq(:aborted)
            end
        end
    end

    describe '#suspend' do
        it 'suspends the system' do
            @options.paths.checks  = fixtures_path + '/signature_check/'

            Arachni::Framework.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.plugins.load :wait
                f.checks.load :signature

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while Arachni::Data.issues.size < 2

                @snapshot = f.suspend
                t.join

                expect(Arachni::Data.issues.size).to be < 500
            end

            expect(Arachni::Snapshot.load( @snapshot )).to be_truthy
        end

        it 'sets #status to :suspended' do
            Arachni::Framework.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links
                f.checks.load :signature

                t = Thread.new do
                    f.run
                end
                sleep 0.1 while f.status != :scanning

                @snapshot = f.suspend
                expect(f.status).to eq(:suspended)

                t.join
                expect(f.status).to eq(:suspended)
            end
        end

        it 'suspends plugins' do
            Arachni::Options.plugins['suspendable'] = {
                'my_option' => 'my value'
            }

            Arachni::Framework.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.checks.load :signature
                f.plugins.load :suspendable

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while f.status != :scanning

                f.suspend
                t.join

                expect(Arachni::State.plugins.runtime[:suspendable][:data]).to eq(1)
            end
        end

        it 'waits for the BrowserCluster jobs to finish'

        context "when #{Arachni::OptionGroups::Snapshot}#save_path" do
            context 'is a directory' do
                it 'stores the snapshot under it' do
                    @options.paths.checks       = fixtures_path + '/signature_check/'
                    @options.snapshot.save_path = Dir.tmpdir

                    Arachni::Framework.new do |f|
                        f.options.url = web_server_url_for :framework_multi
                        f.options.audit.elements :links

                        f.plugins.load :wait
                        f.checks.load :signature

                        t = Thread.new do
                            f.run
                        end

                        sleep 0.1 while Arachni::Data.issues.size < 2

                        @snapshot = f.suspend
                        t.join

                        expect(Arachni::Data.issues.size).to be < 500
                    end

                    expect(File.dirname( @snapshot )).to eq(Dir.tmpdir)
                    expect(Arachni::Snapshot.load( @snapshot )).to be_truthy
                end
            end

            context 'is a file path' do
                it 'stores the snapshot there' do
                    @options.paths.checks       = fixtures_path + '/signature_check/'
                    @options.snapshot.save_path = "#{Dir.tmpdir}/snapshot"

                    Arachni::Framework.new do |f|
                        f.options.url = web_server_url_for :framework_multi
                        f.options.audit.elements :links

                        f.plugins.load :wait
                        f.checks.load :signature

                        t = Thread.new do
                            f.run
                        end

                        sleep 0.1 while Arachni::Data.issues.size < 2

                        @snapshot = f.suspend
                        t.join

                        expect(Arachni::Data.issues.size).to be < 500
                    end

                    expect(@snapshot).to eq("#{Dir.tmpdir}/snapshot")
                    expect(Arachni::Snapshot.load( @snapshot )).to be_truthy
                end
            end
        end
    end

    describe '#restore' do
        it 'restores a suspended scan' do
            @options.paths.checks  = fixtures_path + '/signature_check/'

            logged_issues = 0
            Arachni::Framework.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.plugins.load :wait
                f.checks.load :signature

                Arachni::Data.issues.on_new do
                    logged_issues += 1
                end

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while logged_issues < 200

                @snapshot = f.suspend
                t.join

                expect(logged_issues).to be < 500
            end

            reset_options
            @options.paths.checks  = fixtures_path + '/signature_check/'

            Arachni::Framework.new do |f|
                f.restore @snapshot

                Arachni::Data.issues.on_new do
                    logged_issues += 1
                end
                f.run

                expect(Arachni::Data.issues.size).to eq(500)

                expect(f.report.plugins[:wait][:results]).to eq({ 'stuff' => true })
            end
        end

        it 'restores options' do
            options_hash = nil

            Arachni::Framework.new do |f|
                f.options.url = @url + '/with_ajax'
                f.options.audit.elements :links, :forms, :cookies
                f.options.datastore.my_custom_option = 'my custom value'
                options_hash = f.options.update( f.options.to_rpc_data ).to_h.deep_clone

                f.checks.load :signature

                t = Thread.new { f.run }

                sleep 0.1 while f.browser_cluster.done?
                @snapshot = f.suspend

                t.join
            end

            Arachni::Framework.restore( @snapshot ) do |f|
                expect(f.options.to_h).to eq(options_hash.merge( checks: ['signature'] ))
                expect(f.browser_cluster_job_skip_states).to be_any
            end
        end

        it 'restores BrowserCluster skip states' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/with_ajax'
                f.options.audit.elements :links, :forms, :cookies

                f.checks.load :signature

                t = Thread.new { f.run }

                sleep 0.1 while f.browser_cluster.done?
                @snapshot = f.suspend

                t.join
            end

            Arachni::Framework.restore( @snapshot ) do |f|
                expect(f.browser_cluster_job_skip_states).to be_any
            end
        end

        it 'restores loaded checks' do
            Arachni::Framework.new do |f|
                f.options.url = @url
                f.checks.load :signature

                t = Thread.new { f.run }
                sleep 0.1 while f.status != :scanning

                @snapshot = f.suspend

                t.join
            end

            Arachni::Framework.restore( @snapshot ) do |f|
                expect(f.checks.loaded).to eq(['signature'])
            end
        end

        it 'restores loaded plugins' do
            Arachni::Framework.new do |f|
                f.options.url = @url
                f.plugins.load :wait

                t = Thread.new { f.run }
                sleep 0.1 while f.status != :scanning

                @snapshot = f.suspend
                t.join
            end

            Arachni::Framework.restore( @snapshot ) do |f|
                expect(f.plugins.loaded).to eq(['wait'])
            end
        end

        it 'restores plugin states' do
            Arachni::Options.plugins['suspendable'] = {
                'my_option' => 'my value'
            }

            Arachni::Framework.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.checks.load :signature
                f.plugins.load :suspendable

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while f.status != :scanning

                @snapshot = f.suspend
                t.join

                expect(Arachni::State.plugins.runtime[:suspendable][:data]).to eq(1)
            end

            Arachni::Framework.restore( @snapshot ) do |f|
                t = Thread.new do
                    f.run
                end

                sleep 0.1 while f.status != :scanning

                expect(f.plugins.jobs[:suspendable][:instance].counter).to eq(2)

                f.abort
                t.join
            end
        end
    end

    describe '#pause' do
        it 'pauses the system' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :signature

                t = Thread.new do
                    f.run
                end

                f.pause

                sleep 10

                expect(f.running?).to be_truthy
                t.kill
            end
        end

        it 'returns an Integer request ID' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :signature

                t = Thread.new do
                    f.run
                end

                expect(f.pause).to be_kind_of Integer

                sleep 10

                expect(f.running?).to be_truthy
                t.kill
            end
        end

        it 'sets #status to :paused' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :signature

                t = Thread.new do
                    f.run
                end
                sleep 0.1 while f.status != :scanning

                f.pause
                expect(f.status).to eq(:paused)

                t.kill
            end
        end
    end

    describe '#resume' do
        it 'resumes the system' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :signature

                t = Thread.new do
                    f.run
                end

                id = f.pause

                sleep 10

                expect(f.running?).to be_truthy
                f.resume id
                t.join
            end
        end

        it 'sets #status to scanning' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :signature

                t = Thread.new do
                    f.run
                end

                id = f.pause
                expect(f.status).to eq(:paused)

                f.resume id
                Timeout.timeout( 5 ) do
                    sleep 0.1 while f.status != :scanning
                end
                t.join
            end
        end
    end

    describe '#clean_up' do
        it 'shuts down the #browser_cluster' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'

                expect(f.browser_cluster).to receive(:shutdown)
                f.clean_up
            end
        end

        it 'stops the #plugins' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.plugins.load :wait

                f.plugins.run
                f.clean_up
                expect(f.plugins.jobs).to be_empty
            end
        end

        it 'sets the status to cleanup' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'

                f.clean_up
                expect(f.status).to eq(:cleanup)
            end
        end

        it 'clears the page queue' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.push_to_page_queue Arachni::Page.from_url( f.options.url )

                expect(f.data.page_queue).not_to be_empty
                f.clean_up
                expect(f.data.page_queue).to be_empty
            end
        end

        it 'clears the URL queue' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.push_to_url_queue f.options.url

                expect(f.data.url_queue).not_to be_empty
                f.clean_up
                expect(f.data.url_queue).to be_empty
            end
        end

        it 'sets #running? to false' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.clean_up
                expect(f).not_to be_running
            end
        end
    end

end
