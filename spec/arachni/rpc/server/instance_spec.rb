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

    it 'supports UNIX sockets', if: Arachni::Reactor.supports_unix_sockets? do
        socket = "#{Dir.tmpdir}/arachni-instance-#{@utils.generate_token}"
        @instance = instance_spawn( socket: socket )
        expect(@instance.framework.multi_self_url).to eq(socket)
        expect(@instance.service.alive?).to be_truthy
    end

    describe '#snapshot_path' do
        context 'when the scan has not been suspended' do
            it 'returns nil' do
                expect(@shared_instance.service.snapshot_path).to be_nil
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

                Timeout.timeout 20 do
                    sleep 1 while @instance.service.status != :scanning
                end

                @instance.service.suspend

                Timeout.timeout 20 do
                    sleep 1 while @instance.service.status != :suspended
                end

                expect(File.exists?( @instance.service.snapshot_path )).to be_truthy
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

            Timeout.timeout 20 do
                sleep 1 while @instance.service.status != :scanning
            end

            @instance.service.suspend

            Timeout.timeout 20 do
                sleep 1 while @instance.service.status != :suspended
            end

            expect(File.exists?( @instance.service.snapshot_path )).to be_truthy
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

                Timeout.timeout 20 do
                    sleep 1 while @instance.service.status != :scanning
                end

                expect { @instance.service.suspend }.to raise_error Arachni::RPC::Exceptions::RemoteException
            end
        end
    end

    describe '#suspended?' do
        context 'when the scan has not been suspended' do
            it 'returns false' do
                expect(@shared_instance.service.suspended?).to be_falsey
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

                Timeout.timeout 20 do
                    sleep 1 while @instance.service.status != :scanning
                end

                @instance.service.suspend

                Timeout.timeout 20 do
                    sleep 1 while @instance.service.status != :suspended
                end

                expect(@instance.service.suspended?).to be_truthy
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

            Timeout.timeout 20 do
                sleep 1 while @instance.service.status != :scanning
            end

            options = @instance.service.report[:options]

            @instance.service.suspend

            Timeout.timeout 20 do
                sleep 1 while @instance.service.status != :suspended
            end

            snapshot_path = @instance.service.snapshot_path
            @instance.service.shutdown

            @instance = instance_spawn
            @instance.service.restore snapshot_path

            File.delete snapshot_path

            sleep 1 while @instance.service.status != :scanning

            expect(@instance.service.report[:options]).to eq(options)
        end
    end

    describe '#service' do
        describe '#errors' do
            context 'when no argument has been provided' do
                it 'returns all logged errors' do
                    test = 'Test'
                    @shared_instance.service.error_test test
                    expect(@shared_instance.service.errors.last).to end_with test
                end
            end
            context 'when a start line-range has been provided' do
                it 'returns all logged errors after that line' do
                    initial_errors = @shared_instance.service.errors
                    errors = @shared_instance.service.errors( 10 )

                    expect(initial_errors[10..-1]).to eq(errors)
                end
            end
        end

        describe '#error_logfile' do
            it 'returns the path to the error logfile' do
                errors = IO.read( @shared_instance.service.error_logfile ).split( "\n" )
                expect(errors).to eq(@shared_instance.service.errors)
            end
        end
        describe '#alive?' do
            it 'returns true' do
                expect(@shared_instance.service.alive?).to eq(true)
            end
        end
        describe '#paused?' do
            context 'when not paused' do
                it 'returns false' do
                    @instance = instance_spawn
                    expect(@instance.service.paused?).to be_falsey
                end
            end
            context 'when paused' do
                it 'returns true' do
                    @instance = instance = instance_spawn
                    instance.service.scan(
                        url:    web_server_url_for( :framework ),
                        checks: :test
                    )

                    instance.service.pause
                    expect(instance.service.status).to eq(:pausing)

                    Timeout.timeout 20 do
                        sleep 1 while !instance.service.paused?
                    end

                    expect(instance.service.paused?).to be_truthy
                end
            end
        end
        describe '#resume' do
            it 'resumes the scan' do
                @instance = instance = instance_spawn
                instance.service.scan(
                    url:    web_server_url_for( :framework ),
                    checks: :test
                )

                instance.service.pause
                expect(instance.service.status).to eq(:pausing)

                Timeout.timeout 20 do
                    sleep 1 while !instance.service.paused?
                end

                expect(instance.service.paused?).to be_truthy
                expect(instance.service.resume).to be_truthy

                Timeout.timeout 20 do
                    sleep 1 while instance.service.paused?
                end

                expect(instance.service.paused?).to be_falsey
            end
        end

        [:list_platforms, :list_checks, :list_plugins, :list_reporters, :busy?].each do |m|
            describe "##{m}" do
                it "delegates to Framework##{m}" do
                    expect(@shared_instance.service.send(m)).to eq(@shared_instance.framework.send(m))
                end
            end
        end

        describe '#report' do
            it "returns #{Arachni::Framework}#report as a Hash" do
                instance_report  = @shared_instance.service.report
                framework_report = Arachni::RPC::Serializer.load(
                    Arachni::RPC::Serializer.dump( @shared_instance.framework.report.to_h )
                )

                [:start_datetime, :finish_datetime, :delta_time].each do |k|
                    instance_report.delete k
                    framework_report.delete k
                end

                expect(instance_report).to eq(framework_report)
            end
        end

        describe '#abort_and_report' do
            it 'cleans-up and returns the report as a Hash' do
                expect(@shared_instance.service.abort_and_report).to eq(
                    Arachni::RPC::Serializer.load(
                        Arachni::RPC::Serializer.dump( @shared_instance.framework.report.to_h )
                    )
                )
            end
        end

        describe '#native_abort_and_report' do
            it "cleans-up and returns the report as #{Arachni::Report}" do
                expect(@shared_instance.service.native_abort_and_report).to eq(
                    @shared_instance.framework.report
                )
            end
        end

        describe '#abort_and_report_as' do
            it 'cleans-up and delegate to #report_as' do
                expect(JSON.load( @shared_instance.service.abort_and_report_as( :json ) )).to include 'issues'
            end
        end

        describe '#report_as' do
            it 'delegates to Framework#report_as' do
                expect(JSON.load( @shared_instance.service.report_as( :json ) )).to include 'issues'
            end
        end

        describe '#status' do
            it 'delegate to Framework#status' do
                expect(@shared_instance.service.status).to eq(@shared_instance.framework.status)
            end
        end

        describe '#scan' do
            it 'configures and starts a scan' do
                @instance = instance = instance_spawn

                slave = instance_spawn

                expect(instance.service.busy?).to  eq(instance.framework.busy?)
                expect(instance.service.status).to eq(instance.framework.status)

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
                expect(instance.service.scan).to be_falsey

                sleep 1 while instance.service.busy?

                expect(instance.framework.progress[:instances].size).to eq(2)

                expect(instance.service.busy?).to  eq(instance.framework.busy?)
                expect(instance.service.status).to eq(instance.framework.status)
                expect(instance.service.report['issues']).to be_any
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

            describe ':spawns' do
                context 'when it has a Dispatcher' do
                    context 'which is a Grid member' do
                        context 'with OptionGroup::Dispatcher#grid_mode set to' do
                            context ':aggregate' do
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
                                    expect(instance.service.scan).to be_falsey

                                    sleep 1 while instance.service.busy?

                                    # Since we've only got 3 Dispatchers in the Grid.
                                    expect(instance.framework.progress[:instances].size).to eq(3)

                                    expect(instance.service.busy?).to  eq(instance.framework.busy?)
                                    expect(instance.service.status).to eq(instance.framework.status)
                                    expect(instance.service.report['issues']).to be_any
                                end
                            end
                            context ':balance' do
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
                                    expect(instance.service.scan).to be_falsey

                                    sleep 1 while instance.service.busy?

                                    # No matter how many grid members with unique Pipe-IDs there are
                                    # since we're in balance mode.
                                    expect(instance.framework.progress[:instances].size).to eq(5)

                                    expect(instance.service.busy?).to  eq(instance.framework.busy?)
                                    expect(instance.service.status).to eq(instance.framework.status)
                                    expect(instance.service.report['issues']).to be_any
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
                            context 'true' do
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
                                    expect(instance.service.scan).to be_falsey

                                    sleep 1 while instance.service.busy?

                                    # No matter how many grid members with unique Pipe-IDs there are
                                    # since we're in balance mode.
                                    expect(instance.framework.progress[:instances].size).to eq(5)

                                    expect(instance.service.busy?).to  eq(instance.framework.busy?)
                                    expect(instance.service.status).to eq(instance.framework.status)
                                    expect(instance.service.report['issues']).to be_any
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

                                expect(raised).to be_truthy
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

                                expect(raised).to be_truthy
                            end
                        end

                    end
                end

                context 'when it does not have a Dispatcher' do
                    it 'spawns a number of slaves' do
                        @instance = instance = instance_spawn

                        instance.service.scan(
                            url:    web_server_url_for( :framework ),
                            audit:  { elements: [:links, :forms] },
                            checks: :test,
                            spawns: 4
                        )

                        sleep 1 while instance.service.busy?

                        expect(instance.framework.progress[:instances].size).to eq(5)

                        expect(instance.service.busy?).to  eq(instance.framework.busy?)
                        expect(instance.service.status).to eq(instance.framework.status)
                        expect(instance.service.report['issues']).to be_any
                    end
                end
            end
        end

        describe '#progress' do
            before( :all ) do
                @progress_instance = instance_spawn
                @progress_instance.service.scan(
                    url: web_server_url_for( :framework_multi ),
                    scope: {
                        page_limit: 10
                    },
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
                expect(p[:busy]).to   eq(instance.framework.busy?)
                expect(p[:status]).to eq(instance.framework.status)
                expect(p[:statistics]).to  be_any

                expect(p[:instances]).to be_nil
                expect(p[:issues]).to be_nil
                expect(p[:seed]).not_to be_empty
            end

            describe ':without' do
                describe ':statistics' do
                    it 'includes statistics' do
                        expect(@progress_instance.service.progress(
                            without: :statistics
                        )).not_to include :statistics
                    end
                end
                describe ':issues' do
                    it 'does not include issues with the given Issue#digest hashes' do
                        p = @progress_instance.service.progress( with: :issues )
                        issue = p[:issues].first
                        digest = issue['digest']

                        p = @progress_instance.service.progress(
                            with:    :issues,
                            without: { issues: [digest] }
                        )

                        expect(p[:issues].include?( issue )).to be_falsey
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
                            without: [ :statistics,  issues: [digest] ]
                        )
                        expect(p).not_to include :statistics
                        expect(p[:issues].include?( issue )).to be_falsey
                    end
                end
            end

            describe ':with' do
                describe ':issues' do
                    it 'includes issues' do
                        instance = @progress_instance

                        issues = instance.service.progress( with: :issues )[:issues]
                        expect(issues).to be_any
                        expect(issues.first.class).to eq(Hash)
                        expect(issues).to eq(instance.framework.progress( as_hash: true )[:issues])
                    end
                end

                describe ':instances' do
                    it 'includes instances' do
                        instance = @progress_instance

                        stats1 = instance.service.progress( with: :instances )[:instances]
                        stats2 = instance.framework.progress[:instances]

                        stats1.each do |h|
                            h[:statistics][:http].delete :burst_responses_per_second
                            h[:statistics].delete :runtime
                        end

                        stats2.each do |h|
                            h[:statistics][:http].delete :burst_responses_per_second
                            h[:statistics].delete :runtime
                        end

                        expect(stats1.size).to eq(2)
                        expect(stats1.to_s).to eq(stats2.to_s)
                    end
                end

                describe ':sitemap' do
                    context 'when set to true' do
                        it 'returns entire sitemap' do
                            instance = @progress_instance

                            expect(instance.service.
                                progress( with: { sitemap: true } )[:sitemap]).to eq(
                                    instance.service.sitemap
                            )
                        end
                    end

                    context 'when an index has been provided' do
                        it 'returns all entries after that line' do
                            instance = @progress_instance

                            expect(instance.service.
                                progress( with: { sitemap: 10 } )[:sitemap]).to eq(
                                    instance.service.sitemap( 10 )
                            )
                        end
                    end
                end

                context 'with an array of things to be included'  do
                    it 'includes those things' do
                        instance = @progress_instance

                        p = instance.service.progress(
                            with:    [ :issues, :instances ],
                            without: :statistics
                        )
                        expect(p[:busy]).to   eq(instance.framework.busy?)
                        expect(p[:status]).to eq(instance.framework.status)
                        expect(p[:statistics]).to  be_nil

                        expect(p[:instances].size).to eq(2)
                        expect(p[:issues]).to be_any
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
                expect(p[:busy]).to   eq(instance.framework.busy?)
                expect(p[:status]).to eq(instance.framework.status)
                expect(p[:statistics]).to  be_any

                expect(p[:instances]).to be_nil
                expect(p[:issues]).to be_nil
            end

            describe ':without' do
                describe ':statistics' do
                    it 'includes statistics' do
                        expect(@progress_instance.service.native_progress(
                            without: :statistics
                        )).not_to include :statistics
                    end
                end
                describe ':issues' do
                    it 'does not include issues with the given Issue#digest hashes' do
                        p = @progress_instance.service.native_progress( with: :issues )
                        issue = p[:issues].first
                        digest = issue.digest

                        p = @progress_instance.service.native_progress(
                            with:    :issues,
                            without: { issues: [digest] }
                        )

                        expect(p[:issues].include?( issue )).to be_falsey
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
                            without: [ :statistics,  issues: [digest] ]
                        )
                        expect(p).not_to include :statistics
                        expect(p[:issues].include?( issue )).to be_falsey
                    end
                end
            end

            describe ':with' do
                describe ':issues' do
                    it 'includes issues as Arachni::Issue objects' do
                        instance = @progress_instance

                        issues = instance.service.native_progress( with: :issues )[:issues]
                        expect(issues).to be_any
                        expect(issues.first.class).to eq(Arachni::Issue)
                    end
                end

                describe ':instances' do
                    it 'includes instances' do
                        instance = @progress_instance

                        stats1 = instance.service.native_progress( with: :instances )[:instances]
                        stats2 = instance.framework.progress[:instances]

                        stats1.each do |h|
                            h[:statistics][:http].delete :burst_responses_per_second
                            h[:statistics].delete :runtime
                        end

                        stats2.each do |h|
                            h[:statistics][:http].delete :burst_responses_per_second
                            h[:statistics].delete :runtime
                        end

                        expect(stats1.size).to eq(2)
                        expect(stats1.to_s).to eq(stats2.to_s)
                    end
                end

                context 'with an array of things to be included'  do
                    it 'includes those things' do
                        instance = @progress_instance

                        p = instance.service.native_progress(
                            with:    [ :issues, :instances ],
                            without: :statistics
                        )
                        expect(p[:busy]).to   eq(instance.framework.busy?)
                        expect(p[:status]).to eq(instance.framework.status)
                        expect(p[:statistics]).to  be_nil

                        expect(p[:instances].size).to eq(2)
                        expect(p[:issues]).to be_any
                    end
                end
            end
        end

        describe '#shutdown' do
            it 'shuts-down the instance' do
                instance = instance_spawn
                expect(instance.service.shutdown).to be_truthy
                sleep 4

                expect { instance.service.alive? }.to raise_error Arachni::RPC::Exceptions::ConnectionError
            end
        end
    end

    describe '#framework' do
        it 'provides access to the Framework' do
            expect(@shared_instance.framework.busy?).to be_falsey
        end
    end

    describe '#options' do
        it 'provides access to the Options' do
            url = 'http://blah.com'
            @shared_instance.options.url = url
            expect(@shared_instance.options.url.to_s).to eq(@utils.normalize_url( url ))
        end
    end

    describe '#checks' do
        it 'provides access to the checks manager' do
            expect(@shared_instance.checks.available.sort).to eq(%w(test test2 test3).sort)
        end
    end

    describe '#plugins' do
        it 'provides access to the plugin manager' do
            expect(@shared_instance.plugins.available.sort).to eq(%w(wait bad distributable
                loop default with_options suspendable).sort)
        end
    end
end
