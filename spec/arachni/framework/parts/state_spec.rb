require 'spec_helper'

describe Arachni::Framework::Parts::State do
    include_examples 'framework'

    describe '#scanning?' do
        it "delegates to #{Arachni::State::Framework}#scanning?" do
            subject.state.stub(:scanning?) { :stuff }
            subject.scanning?.should == :stuff
        end
    end

    describe '#done?' do
        it "delegates to #{Arachni::State::Framework}#done?" do
            subject.state.stub(:done?) { :stuff }
            subject.done?.should == :stuff
        end
    end

    describe '#paused?' do
        it "delegates to #{Arachni::State::Framework}#paused?" do
            subject.state.stub(:paused?) { :stuff }
            subject.paused?.should == :stuff
        end
    end

    describe '#state' do
        it "returns #{Arachni::State::Framework}" do
            subject.state.should be_kind_of Arachni::State::Framework
        end
    end

    describe '#abort' do
        it 'aborts the system' do
            @options.paths.checks  = fixtures_path + '/taint_check/'

            Arachni::Framework.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.plugins.load :wait
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while Arachni::Data.issues.size < 2

                f.abort
                t.join

                Arachni::Data.issues.size.should < 500
            end
        end

        it 'sets #status to :aborted' do
            Arachni::Framework.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end
                sleep 0.1 while f.status != :scanning

                f.abort
                f.status.should == :aborted

                t.join
                f.status.should == :aborted
            end
        end
    end

    describe '#suspend' do
        it 'suspends the system' do
            @options.paths.checks  = fixtures_path + '/taint_check/'

            Arachni::Framework.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.plugins.load :wait
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while Arachni::Data.issues.size < 2

                @snapshot = f.suspend
                t.join

                Arachni::Data.issues.size.should < 500
            end

            Arachni::Snapshot.load( @snapshot ).should be_true
        end

        it 'sets #status to :suspended' do
            Arachni::Framework.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end
                sleep 0.1 while f.status != :scanning

                @snapshot = f.suspend
                f.status.should == :suspended

                t.join
                f.status.should == :suspended
            end
        end

        it 'suspends plugins' do
            Arachni::Options.plugins['suspendable'] = {
                'my_option' => 'my value'
            }

            Arachni::Framework.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.checks.load  :taint
                f.plugins.load :suspendable

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while f.status != :scanning

                f.suspend
                t.join

                Arachni::State.plugins.runtime[:suspendable][:data].should == 1
            end
        end

        it 'waits for the BrowserCluster jobs to finish'

        context "when #{Arachni::OptionGroups::Snapshot}#save_path" do
            context 'is a directory' do
                it 'stores the snapshot under it' do
                    @options.paths.checks       = fixtures_path + '/taint_check/'
                    @options.snapshot.save_path = Dir.tmpdir

                    Arachni::Framework.new do |f|
                        f.options.url = web_server_url_for :framework_multi
                        f.options.audit.elements :links

                        f.plugins.load :wait
                        f.checks.load :taint

                        t = Thread.new do
                            f.run
                        end

                        sleep 0.1 while Arachni::Data.issues.size < 2

                        @snapshot = f.suspend
                        t.join

                        Arachni::Data.issues.size.should < 500
                    end

                    File.dirname( @snapshot ).should == Dir.tmpdir
                    Arachni::Snapshot.load( @snapshot ).should be_true
                end
            end

            context 'is a file path' do
                it 'stores the snapshot there' do
                    @options.paths.checks       = fixtures_path + '/taint_check/'
                    @options.snapshot.save_path = "#{Dir.tmpdir}/snapshot"

                    Arachni::Framework.new do |f|
                        f.options.url = web_server_url_for :framework_multi
                        f.options.audit.elements :links

                        f.plugins.load :wait
                        f.checks.load :taint

                        t = Thread.new do
                            f.run
                        end

                        sleep 0.1 while Arachni::Data.issues.size < 2

                        @snapshot = f.suspend
                        t.join

                        Arachni::Data.issues.size.should < 500
                    end

                    @snapshot.should == "#{Dir.tmpdir}/snapshot"
                    Arachni::Snapshot.load( @snapshot ).should be_true
                end
            end
        end
    end

    describe '#restore' do
        it 'restores a suspended scan' do
            @options.paths.checks  = fixtures_path + '/taint_check/'

            logged_issues = 0
            Arachni::Framework.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.plugins.load :wait
                f.checks.load :taint

                Arachni::Data.issues.on_new do
                    logged_issues += 1
                end

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while logged_issues < 200

                @snapshot = f.suspend
                t.join

                logged_issues.should < 500
            end

            reset_options
            @options.paths.checks  = fixtures_path + '/taint_check/'

            Arachni::Framework.new do |f|
                f.restore @snapshot

                Arachni::Data.issues.on_new do
                    logged_issues += 1
                end
                f.run

                # logged_issues.should == 500
                Arachni::Data.issues.size.should == 500

                f.report.plugins[:wait][:results].should == { 'stuff' => true }
            end
        end

        it 'restores options' do
            options_hash = nil

            Arachni::Framework.new do |f|
                f.options.url = @url + '/with_ajax'
                f.options.audit.elements :links, :forms, :cookies
                f.options.datastore.my_custom_option = 'my custom value'
                options_hash = f.options.update( f.options.to_rpc_data ).to_h.deep_clone

                f.checks.load :taint

                t = Thread.new { f.run }

                sleep 0.1 while f.browser_cluster.done?
                @snapshot = f.suspend

                t.join
            end

            Arachni::Framework.restore( @snapshot ) do |f|
                f.options.to_h.should == options_hash.merge( checks: ['taint'] )
                f.browser_cluster_job_skip_states.should be_any
            end
        end

        it 'restores BrowserCluster skip states' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/with_ajax'
                f.options.audit.elements :links, :forms, :cookies

                f.checks.load :taint

                t = Thread.new { f.run }

                sleep 0.1 while f.browser_cluster.done?
                @snapshot = f.suspend

                t.join
            end

            Arachni::Framework.restore( @snapshot ) do |f|
                f.browser_cluster_job_skip_states.should be_any
            end
        end

        it 'restores loaded checks' do
            Arachni::Framework.new do |f|
                f.options.url = @url
                f.checks.load :taint

                t = Thread.new { f.run }
                sleep 0.1 while f.status != :scanning

                @snapshot = f.suspend

                t.join
            end

            Arachni::Framework.restore( @snapshot ) do |f|
                f.checks.loaded.should == ['taint']
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
                f.plugins.loaded.should == ['wait']
            end
        end

        it 'restores plugin states' do
            Arachni::Options.plugins['suspendable'] = {
                'my_option' => 'my value'
            }

            Arachni::Framework.new do |f|
                f.options.url = web_server_url_for :framework_multi
                f.options.audit.elements :links

                f.checks.load  :taint
                f.plugins.load :suspendable

                t = Thread.new do
                    f.run
                end

                sleep 0.1 while f.status != :scanning

                @snapshot = f.suspend
                t.join

                Arachni::State.plugins.runtime[:suspendable][:data].should == 1
            end

            Arachni::Framework.restore( @snapshot ) do |f|
                t = Thread.new do
                    f.run
                end

                sleep 0.1 while f.status != :scanning

                f.plugins.jobs[:suspendable][:instance].counter.should == 2

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
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end

                f.pause

                sleep 10

                f.running?.should be_true
                t.kill
            end
        end

        it 'returns an Integer request ID' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end

                f.pause.should be_kind_of Integer

                sleep 10

                f.running?.should be_true
                t.kill
            end
        end

        it 'sets #status to :paused' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end
                sleep 0.1 while f.status != :scanning

                f.pause
                f.status.should == :paused

                t.kill
            end
        end
    end

    describe '#resume' do
        it 'resumes the system' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end

                id = f.pause

                sleep 10

                f.running?.should be_true
                f.resume id
                t.join
            end
        end

        it 'sets #status to scanning' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.options.audit.elements :links, :forms, :cookies
                f.checks.load :taint

                t = Thread.new do
                    f.run
                end

                id = f.pause
                f.status.should == :paused

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

                f.browser_cluster.should receive(:shutdown)
                f.clean_up
            end
        end

        it 'stops the #plugins' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.plugins.load :wait

                f.plugins.run
                f.clean_up
                f.plugins.jobs.should be_empty
            end
        end

        it 'sets the status to cleanup' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'

                f.clean_up
                f.status.should == :cleanup
            end
        end

        it 'clears the page queue' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.push_to_page_queue Arachni::Page.from_url( f.options.url )

                f.data.page_queue.should_not be_empty
                f.clean_up
                f.data.page_queue.should be_empty
            end
        end

        it 'clears the URL queue' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.push_to_url_queue f.options.url

                f.data.url_queue.should_not be_empty
                f.clean_up
                f.data.url_queue.should be_empty
            end
        end

        it 'sets #running? to false' do
            Arachni::Framework.new do |f|
                f.options.url = @url + '/elem_combo'
                f.clean_up
                f.should_not be_running
            end
        end
    end

end
