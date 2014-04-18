require 'json'
require 'spec_helper'

describe 'Arachni::RPC::Server::Instance' do
    before( :all ) do
        @opts     = Arachni::Options.instance
        @utils    = Arachni::Utilities
        @shared_instance = instance_spawn
    end

    before :each do
        @instance = nil
    end
    after :each do
        if @instance
            @instance.service.shutdown

            path = @instance.service.snapshot_path
            File.delete path if path
        end

        dispatcher_killall
    end

    describe '#snapshot_path' do
        context 'when the scan has not been suspended' do
            it 'returns nil' do
                @shared_instance.service.snapshot_path.should be_nil
            end
        end

        context 'when the scan has been suspended' do
            it 'returns the path to the snapshot' do
                @instance = instance_spawn

                @instance.service.scan(
                    url:    web_server_url_for( :framework_multi ),
                    audit:  { elements: [:links, :forms] },
                    checks: :test
                )

                Timeout.timeout 5 do
                    sleep 1 while @instance.service.status != :scanning
                end

                @instance.service.suspend

                Timeout.timeout 5 do
                    sleep 1 while @instance.service.status != :suspended
                end

                File.exists?( @instance.service.snapshot_path ).should be_true
            end
        end
    end

    describe '#suspend' do
        it 'suspends the scan to disk' do
            @instance = instance_spawn

            @instance.service.scan(
                url:    web_server_url_for( :framework_multi ),
                audit:  { elements: [:links, :forms] },
                checks: :test
            )

            Timeout.timeout 5 do
                sleep 1 while @instance.service.status != :scanning
            end

            @instance.service.suspend

            Timeout.timeout 5 do
                sleep 1 while @instance.service.status != :suspended
            end

            File.exists?( @instance.service.snapshot_path ).should be_true
        end

        context 'when performing a multi-Instance scan' do
            it "raises #{Arachni::State::Framework::Error::StateNotSuspendable}" do
                @instance = instance_spawn

                @instance.service.scan(
                    url:    web_server_url_for( :framework_multi ),
                    audit:  { elements: [:links, :forms] },
                    checks: :test,
                    spawns: 2
                )

                Timeout.timeout 5 do
                    sleep 1 while @instance.service.status != :scanning
                end

                expect { @instance.service.suspend }.to raise_error Arachni::RPC::Exceptions::RemoteException
            end
        end
    end

    describe '#suspended?' do
        context 'when the scan has not been suspended' do
            it 'returns false' do
                @shared_instance.service.should_not be_suspended
            end
        end

        context 'when the scan has been suspended' do
            it 'returns true' do
                @instance = instance_spawn

                @instance.service.scan(
                    url:    web_server_url_for( :framework_multi ),
                    audit:  { elements: [:links, :forms] },
                    checks: :test
                )

                Timeout.timeout 5 do
                    sleep 1 while @instance.service.status != :scanning
                end

                @instance.service.suspend

                Timeout.timeout 5 do
                    sleep 1 while @instance.service.status != :suspended
                end

                @instance.service.should be_suspended
            end
        end
    end

    describe '#restore' do
        it 'suspends the scan to disk' do
            @instance = instance_spawn

            @instance.service.scan(
                url:    web_server_url_for( :framework_multi ),
                audit:  { elements: [:links, :forms] },
                checks: :test
            )

            Timeout.timeout 5 do
                sleep 1 while @instance.service.status != :scanning
            end

            options = @instance.service.report[:options]

            @instance.service.suspend

            Timeout.timeout 5 do
                sleep 1 while @instance.service.status != :suspended
            end

            snapshot_path = @instance.service.snapshot_path
            @instance.service.shutdown

            @instance = instance_spawn
            @instance.service.restore snapshot_path

            File.delete snapshot_path

            sleep 1 while @instance.service.busy?

            @instance.service.report[:options].should == options
        end
    end

    it 'supports UNIX sockets' do
        socket = "/tmp/arachni-instance-#{@utils.generate_token}"
        @instance = instance_spawn( socket: socket )
        @instance.framework.multi_self_url.should == socket
        @instance.service.alive?.should be_true
    end

    describe '#service' do
        describe '#errors' do
            context 'when no argument has been provided' do
                it 'returns all logged errors' do
                    test = 'Test'
                    @shared_instance.service.error_test test
                    @shared_instance.service.errors.last.should end_with test
                end
            end
            context 'when a start line-range has been provided' do
                it 'returns all logged errors after that line' do
                    initial_errors = @shared_instance.service.errors
                    errors = @shared_instance.service.errors( 10 )

                    initial_errors[10..-1].should == errors
                end
            end
        end

        describe '#error_logfile' do
            it 'returns the path to the error logfile' do
                errors = IO.read( @shared_instance.service.error_logfile ).split( "\n" )
                errors.should == @shared_instance.service.errors
            end
        end
        describe '#alive?' do
            it 'returns true' do
                @shared_instance.service.alive?.should == true
            end
        end

        describe '#paused?' do
            context 'when not paused' do
                it 'returns false' do
                    @shared_instance.framework.paused?.should be_false
                end
            end
            context 'when paused' do
                it 'returns true' do
                    @shared_instance.framework.pause
                    @shared_instance.framework.paused?.should be_true
                end
            end
        end
        describe '#resume' do
            it 'resumes the scan' do
                @shared_instance.framework.pause
                @shared_instance.framework.paused?.should be_true
                @shared_instance.framework.resume.should be_true
                @shared_instance.framework.paused?.should be_false
            end
        end

        [:list_platforms, :list_checks, :list_plugins, :list_reports, :busy?].each do |m|
            describe "##{m}" do
                it "delegates to Framework##{m}" do
                    @shared_instance.service.send(m).should == @shared_instance.framework.send(m)
                end
            end
        end

        describe '#report' do
            it 'delegates to Framework#report' do
                instance_report  = @shared_instance.service.report
                framework_report = @shared_instance.framework.report

                [:start_datetime, :finish_datetime, :delta_time].each do |k|
                    instance_report.delete k
                    framework_report.delete k
                end

                instance_report.should == framework_report
            end
        end

        describe '#abort_and_report' do
            it 'cleans-up and returns the report as a Hash' do
                @shared_instance.service.abort_and_report.should == @shared_instance.framework.report
            end
        end

        describe '#native_abort_and_report' do
            it "cleans-up and returns the report as #{Arachni::AuditStore}" do
                @shared_instance.service.native_abort_and_report.should == @shared_instance.framework.auditstore
            end
        end


        describe '#abort_and_report_as' do
            it 'cleans-up and delegate to #report_as' do
                JSON.load( @shared_instance.service.abort_and_report_as( :json ) ).should include 'issues'
            end
        end

        describe '#report_as' do
            it 'delegates to Framework#report_as' do
                JSON.load( @shared_instance.service.report_as( :json ) ).should include 'issues'
            end
        end

        describe '#status' do
            it 'delegate to Framework#status' do
                @shared_instance.service.status.should == @shared_instance.framework.status
            end
        end

        describe '#scan' do
            it 'configures and starts a scan' do
                @instance = instance = instance_spawn

                slave = instance_spawn

                instance.service.busy?.should  == instance.framework.busy?
                instance.service.status.should == instance.framework.status

                instance.service.scan(
                    url:    web_server_url_for( :framework ),
                    audit:  { elements: [:links, :forms] },
                    checks: :test,
                    slaves: [{
                        url: slave.url,
                        token: instance_token_for( slave )
                    }]
                )

                # if a scan in already running it should just bail out early
                instance.service.scan.should be_false

                sleep 1 while instance.service.busy?

                instance.framework.progress_data[:instances].size.should == 2

                instance.service.busy?.should  == instance.framework.busy?
                instance.service.status.should == instance.framework.status

                i_report = instance.service.report
                f_report = instance.framework.report

                i_report.should == f_report
                i_report['issues'].should be_any
            end

            context 'with invalid :platforms' do
                it 'raises ArgumentError' do
                    @instance = instance_spawn
                    expect {
                        @instance.service.scan(
                            url:       web_server_url_for( :framework ),
                            platforms: [ :stuff ]
                        )
                    }.to raise_error
                end
            end

            describe :spawns do
                context 'when it has a Dispatcher' do
                    context 'which is a Grid member' do
                        context 'with OptionGroup::Dispatcher#grid_mode set to' do
                            context :aggregate do
                                it 'requests slaves from grid members with unique Pipe-IDs' do
                                    @instance = instance = instance_grid_spawn

                                    instance.service.scan(
                                        url:        web_server_url_for( :framework ),
                                        audit:      { elements: [:links, :forms] },
                                        checks:     :test,
                                        spawns:     4,
                                        grid_mode: :aggregate
                                    )

                                    # if a scan in already running it should just bail out early
                                    instance.service.scan.should be_false

                                    sleep 1 while instance.service.busy?

                                    # Since we've only got 3 Dispatchers in the Grid.
                                    instance.framework.progress_data[:instances].size.should == 3

                                    instance.service.busy?.should  == instance.framework.busy?
                                    instance.service.status.should == instance.framework.status

                                    i_report = instance.service.report
                                    f_report = instance.framework.report

                                    i_report.should == f_report
                                    i_report['issues'].should be_any
                                end
                            end
                            context :balance do
                                it 'requests its slaves from it' do
                                    @instance = instance = instance_grid_spawn

                                    instance.service.scan(
                                        url:        web_server_url_for( :framework ),
                                        audit:      { elements: [:links, :forms] },
                                        checks:     :test,
                                        spawns:     4,
                                        grid_mode: :balance
                                    )

                                    # if a scan in already running it should just bail out early
                                    instance.service.scan.should be_false

                                    sleep 1 while instance.service.busy?

                                    # No matter how many grid members with unique Pipe-IDs there are
                                    # since we're in balance mode.
                                    instance.framework.progress_data[:instances].size.should == 5

                                    instance.service.busy?.should  == instance.framework.busy?
                                    instance.service.status.should == instance.framework.status

                                    i_report = instance.service.report
                                    f_report = instance.framework.report

                                    i_report.should == f_report
                                    i_report['issues'].should be_any
                                end
                            end

                            context 'unknown option' do
                                it 'raises an exception' do
                                    @instance = instance_grid_spawn
                                    expect {
                                        @instance.service.scan(
                                            url:       web_server_url_for( :framework ),
                                            audit:     { elements: [:links, :forms] },
                                            checks:    :test,
                                            spawns:     4,
                                            grid_mode: :blahblah
                                        )
                                    }.to raise_error
                                end
                            end

                        end

                        context 'with :grid set to' do
                            context true do
                                it 'it a shorthand for grid_mode: :balance' do
                                    @instance = instance = instance_grid_spawn

                                    instance.service.scan(
                                        url:    web_server_url_for( :framework ),
                                        audit:  { elements: [:links, :forms] },
                                        checks: :test,
                                        spawns: 4,
                                        grid:   true
                                    )

                                    # if a scan in already running it should just bail out early
                                    instance.service.scan.should be_false

                                    sleep 1 while instance.service.busy?

                                    # No matter how many grid members with unique Pipe-IDs there are
                                    # since we're in balance mode.
                                    instance.framework.progress_data[:instances].size.should == 5

                                    instance.service.busy?.should  == instance.framework.busy?
                                    instance.service.status.should == instance.framework.status

                                    i_report = instance.service.report
                                    f_report = instance.framework.report

                                    i_report.should == f_report
                                    i_report['issues'].should be_any
                                end
                            end
                        end

                        context 'when it is less than 1' do
                            it 'raises an exception' do
                                @instance = instance = instance_grid_spawn

                                raised = false
                                begin
                                    instance.service.scan(
                                        url:        web_server_url_for( :framework ),
                                        grid_mode: :balance
                                    )
                                rescue => e
                                    raised = e.rpc_exception?
                                end

                                raised.should be_true
                            end
                        end

                        context 'when OptionGroup::Scope#restrict_to_paths is set' do
                            it 'raises an exception' do
                                @instance = instance = instance_grid_spawn
                                url      = web_server_url_for( :framework )

                                raised = false
                                begin
                                    instance.service.scan(
                                        url:       url,
                                        grid_mode: :balance,
                                        spawns:    4,
                                        scope:     { restrict_paths: [url] }
                                    )
                                rescue => e
                                    raised = e.rpc_exception?
                                end

                                raised.should be_true
                            end
                        end

                    end
                end

                context 'when it does not have a Dispatcher' do
                    it 'uses UNIX sockets to communicate with the slaves' do
                        @instance = instance = instance_spawn
                        instance.service.scan(
                            url:    web_server_url_for( :framework ),
                            audit:  { elements: [:links, :forms] },
                            checks: :test,
                            spawns: 4
                        )
                        sleep 1 while instance.service.busy?

                        self_url = instance.framework.self_url

                        instance.service.progress( with: :instances )[:instances].each do |progress|
                            url = progress[:url]
                            next if url == self_url
                            File.socket?( url ).should be_true
                        end
                    end

                    it 'spawns a number of slaves' do
                        @instance = instance = instance_spawn

                        instance.service.scan(
                            url:    web_server_url_for( :framework ),
                            audit:  { elements: [:links, :forms] },
                            checks: :test,
                            spawns: 4
                        )

                        sleep 1 while instance.service.busy?

                        instance.framework.progress_data[:instances].size.should == 5

                        instance.service.busy?.should  == instance.framework.busy?
                        instance.service.status.should == instance.framework.status

                        i_report = instance.service.report
                        f_report = instance.framework.report

                        i_report.should == f_report
                        i_report['issues'].should be_any
                    end
                end
            end
        end

        describe '#progress' do
            before( :all ) do
                @progress_instance = instance_spawn
                @progress_instance.service.scan(
                    url:    web_server_url_for( :framework ),
                    audit:  { elements: [:links, :forms] },
                    checks: :test,
                    spawns: 1
                )
                sleep 1 while @progress_instance.service.busy?
            end
            after :all do
                @progress_instance.service.shutdown
            end

            it 'returns progress information' do
                instance = @progress_instance

                p = instance.service.progress
                p[:busy].should   == instance.framework.busy?
                p[:status].should == instance.framework.status
                p[:stats].should  be_any

                p[:instances].should be_nil
                p[:issues].should be_nil
            end

            describe :without do
                describe :stats do
                    it 'includes stats' do
                        @progress_instance.service.progress( without: :stats )[:stats].should be_nil
                    end
                end
                describe :issues do
                    it 'does not include issues with the given Issue#digest hashes' do
                        p = @progress_instance.service.progress( with: :issues )
                        issue = p[:issues].first
                        digest = issue['digest']

                        p = @progress_instance.service.progress(
                            with:    :issues,
                            without: { issues: [digest] }
                        )

                        p[:issues].include?( issue ).should be_false
                    end
                end
                context 'with an array of things to be excluded'  do
                    it 'excludes those things' do
                        instance = @progress_instance

                        p = @progress_instance.service.progress( with: :issues )
                        issue = p[:issues].first
                        digest = issue['digest']

                        p = instance.service.progress(
                            with:    [ :issues, :instances ],
                            without: [ :stats,  issues: [digest] ]
                        )
                        p[:stats].should be_nil
                        p[:issues].include?( issue ).should be_false
                    end
                end
            end

            describe :with do
                describe :issues do
                    it 'includes issues' do
                        instance = @progress_instance

                        issues = instance.service.progress( with: :issues )[:issues]
                        issues.should be_any
                        issues.first.class.should == Hash
                        issues.should == instance.framework.progress_data( as_hash: true )[:issues]
                    end
                end

                describe :instances do
                    it 'includes instances' do
                        instance = @progress_instance

                        stats1 = instance.service.progress( with: :instances )[:instances]
                        stats2 = instance.framework.progress_data[:instances]

                        # Average req/s may differ.
                        stats1.each { |h| h.delete :curr_avg; h.delete :avg }
                        stats2.each { |h| h.delete :curr_avg; h.delete :avg }

                        stats1.size.should == 2
                        stats1.should == stats2
                    end
                end

                context 'with an array of things to be included'  do
                    it 'includes those things' do
                        instance = @progress_instance

                        p = instance.service.progress(
                            with:    [ :issues, :instances ],
                            without: :stats
                        )
                        p[:busy].should   == instance.framework.busy?
                        p[:status].should == instance.framework.status
                        p[:stats].should  be_nil

                        p[:instances].size.should == 2
                        p[:issues].should be_any
                    end
                end
            end
        end

        describe '#native_progress' do
            before( :all ) do
                @progress_instance = instance_spawn
                @progress_instance.service.scan(
                    url:    web_server_url_for( :framework ),
                    audit:  { elements: [:links, :forms] },
                    checks: :test,
                    spawns: 1
                )
                sleep 1 while @progress_instance.service.busy?
            end
            after :all do
                @progress_instance.service.shutdown
            end

            it 'returns progress information' do
                instance = @progress_instance

                p = instance.service.native_progress
                p[:busy].should   == instance.framework.busy?
                p[:status].should == instance.framework.status
                p[:stats].should  be_any

                p[:instances].should be_nil
                p[:issues].should be_nil
            end

            describe :without do
                describe :stats do
                    it 'includes stats' do
                        @progress_instance.service.native_progress( without: :stats )[:stats].should be_nil
                    end
                end
                describe :issues do
                    it 'does not include issues with the given Issue#digest hashes' do
                        p = @progress_instance.service.native_progress( with: :issues )
                        issue = p[:issues].first
                        digest = issue.digest

                        p = @progress_instance.service.native_progress(
                            with: :issues,
                            without: { issues: [digest] }
                        )

                        p[:issues].include?( issue ).should be_false
                    end
                end
                context 'with an array of things to be excluded'  do
                    it 'excludes those things' do
                        instance = @progress_instance

                        p = @progress_instance.service.native_progress( with: :issues )
                        issue = p[:issues].first
                        digest = issue.digest

                        p = instance.service.native_progress(
                            with:    [ :issues, :instances ],
                            without: [ :stats,  issues: [digest] ]
                        )
                        p[:stats].should be_nil
                        p[:issues].include?( issue ).should be_false
                    end
                end
            end

            describe :with do
                describe :issues do
                    it 'includes issues' do
                        instance = @progress_instance

                        issues = instance.service.native_progress( with: :issues )[:issues]
                        issues.should be_any
                        issues.should == instance.framework.progress_data( as_hash: false )[:issues]
                    end
                end

                describe :native_issues do
                    it 'includes issues as Arachni::Issue objects' do
                        instance = @progress_instance

                        issues = instance.service.native_progress( with: :issues )[:issues]
                        issues.should be_any
                        issues.first.class.should == Arachni::Issue
                    end
                end

                describe :instances do
                    it 'includes instances' do
                        instance = @progress_instance

                        stats1 = instance.service.native_progress( with: :instances )[:instances]
                        stats2 = instance.framework.progress_data[:instances]

                        # Average req/s may differ.
                        stats1.each { |h| h.delete :curr_avg; h.delete :avg }
                        stats2.each { |h| h.delete :curr_avg; h.delete :avg }

                        stats1.size.should == 2
                        stats1.should == stats2
                    end
                end

                context 'with an array of things to be included'  do
                    it 'includes those things' do
                        instance = @progress_instance

                        p = instance.service.native_progress(
                            with:    [ :issues, :instances ],
                            without: :stats
                        )
                        p[:busy].should   == instance.framework.busy?
                        p[:status].should == instance.framework.status
                        p[:stats].should  be_nil

                        p[:instances].size.should == 2
                        p[:issues].should be_any
                    end
                end
            end
        end

        describe '#shutdown' do
            it 'shuts-down the instance' do
                instance = instance_spawn
                instance.service.shutdown.should be_true
                sleep 4

                expect { instance.service.alive? }.to raise_error
            end
        end
    end

    describe '#framework' do
        it 'provides access to the Framework' do
            @shared_instance.framework.busy?.should be_false
        end
    end

    describe '#opts' do
        it 'provides access to the Options' do
            url = 'http://blah.com'
            @shared_instance.opts.url = url
            @shared_instance.opts.url.to_s.should == @utils.normalize_url( url )
        end
    end

    describe '#checks' do
        it 'provides access to the checks manager' do
            @shared_instance.checks.available.sort.should == %w(test test2 test3).sort
        end
    end

    describe '#plugins' do
        it 'provides access to the plugin manager' do
            @shared_instance.plugins.available.sort.should == %w(wait bad distributable
                loop default with_options suspendable).sort
        end
    end
end
