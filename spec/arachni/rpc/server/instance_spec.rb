require 'spec_helper'

describe 'Arachni::RPC::Server::Instance' do
    before( :all ) do
        @opts     = Arachni::Options.instance
        @utils    = Arachni::Module::Utilities
        @instance = instance_spawn
    end

    it 'supports UNIX sockets' do
        socket = '/tmp/arachni-instance'
        instance = instance_spawn( socket: socket )
        instance.framework.multi_self_url.should == socket
        instance.service.alive?.should be_true
    end

    describe '#service' do
        describe '#errors' do
            context 'when no argument has been provided' do
                it 'returns all logged errors' do
                    test = 'Test'
                    @instance.service.error_test test
                    @instance.service.errors.last.should end_with test
                end
            end
            context 'when a start line-range has been provided' do
                it 'returns all logged errors after that line' do
                    initial_errors = @instance.service.errors
                    errors = @instance.service.errors( 10 )

                    initial_errors[10..-1].should == errors
                end
            end
        end

        describe '#error_logfile' do
            it 'returns the path to the error logfile' do
                errors = IO.read( @instance.service.error_logfile ).split( "\n" )
                errors.should == @instance.service.errors
            end
        end
        describe '#alive?' do
            it 'returns true' do
                @instance.service.alive?.should == true
            end
        end

        describe '#paused?' do
            context 'when not paused' do
                it 'returns false' do
                    @instance.framework.paused?.should be_false
                end
            end
            context 'when paused' do
                it 'returns true' do
                    @instance.framework.pause
                    @instance.framework.paused?.should be_true
                end
            end
        end
        describe '#resume' do
            it 'resumes the scan' do
                @instance.framework.pause
                @instance.framework.paused?.should be_true
                @instance.framework.resume.should be_true
                @instance.framework.paused?.should be_false
            end
        end

        [:list_platforms, :list_modules, :list_plugins, :list_reports, :busy?, :report].each do |m|
            describe "##{m}" do
                it "delegates to Framework##{m}" do
                    @instance.service.send(m).should == @instance.framework.send(m)
                end
            end
        end

        describe '#abort_and_report' do
            describe 'nil' do
                it 'cleans-up and returns the report as a Hash' do
                    @instance.service.abort_and_report.should == @instance.framework.report
                end
            end

            describe :auditstore do
                it 'delegates to Framework#auditstore' do
                    @instance.service.abort_and_report( :auditstore ).should == @instance.framework.auditstore
                end
            end
        end

        describe '#abort_and_report_as' do
            it 'cleans-up and delegate to #report_as' do
                Nokogiri::HTML( @instance.service.abort_and_report_as( :html ) ).title.should be_true
            end
        end

        describe '#report_as' do
            it 'delegates to Framework#report_as' do
                Nokogiri::HTML( @instance.service.report_as( :html ) ).title.should be_true
            end
        end

        describe '#status' do
            it 'delegate to Framework#status' do
                @instance.service.status.should == @instance.framework.status
            end
        end

        describe '#scan' do
            it 'configures and starts a scan' do
                instance = instance_spawn

                slave = instance_spawn

                instance.service.busy?.should  == instance.framework.busy?
                instance.service.status.should == instance.framework.status

                instance.service.scan(
                    url:         web_server_url_for( :framework_simple ),
                    audit_links: true,
                    audit_forms: true,
                    modules:     :test,
                    slaves:      [{
                        url: slave.url,
                        token: instance_token_for( slave )
                    }]
                )

                # if a scan in already running it should just bail out early
                instance.service.scan.should be_false

                sleep 1 while instance.service.busy?

                instance.framework.progress_data['instances'].size.should == 2

                instance.service.busy?.should  == instance.framework.busy?
                instance.service.status.should == instance.framework.status

                i_report = instance.service.report
                f_report = instance.framework.report

                i_report.should == f_report
                i_report['issues'].should be_any
            end

            context 'with invalid :platforms' do
                it 'raises ArgumentError' do
                    expect {
                        instance_spawn.service.scan(
                            url:         web_server_url_for( :framework_simple ),
                            platforms:   [ :stuff ]
                        )
                    }.to raise_error
                end
            end

            context 'when the options Hash uses Strings instead of Symbols' do
                it 'makes no difference' do
                    instance = instance_spawn
                    slave    = instance_spawn

                    instance.service.busy?.should  == instance.framework.busy?
                    instance.service.status.should == instance.framework.status

                    instance.service.scan(
                        'url'         => web_server_url_for( :framework_simple ),
                        'audit_links '=> true,
                        'audit_forms' => true,
                        'modules'     => 'test',
                        slaves:      [{
                            url: slave.url,
                            token: instance_token_for( slave )
                        }]
                    )

                    # if a scan in already running it should just bail out early
                    instance.service.scan.should be_false

                    sleep 1 while instance.service.busy?

                    instance.framework.progress_data['instances'].size.should == 2

                    instance.service.busy?.should  == instance.framework.busy?
                    instance.service.status.should == instance.framework.status

                    i_report = instance.service.report
                    f_report = instance.framework.report

                    i_report.should == f_report
                    i_report['issues'].should be_any

                end
            end

            describe :spawns do
                context 'when it has a Dispatcher' do
                    context 'which is a Grid member' do
                        context 'with grid_mode set to' do
                            context :aggregate do
                                it 'requests slaves from grid members with unique Pipe-IDs' do
                                    instance = instance_grid_spawn

                                    instance.service.scan(
                                        url:         web_server_url_for( :framework_simple ),
                                        audit_links: true,
                                        audit_forms: true,
                                        modules:     :test,
                                        spawns:      4,
                                        grid_mode:   :aggregate
                                    )

                                    # if a scan in already running it should just bail out early
                                    instance.service.scan.should be_false

                                    sleep 1 while instance.service.busy?

                                    # Since we've only got 3 Dispatchers in the Grid.
                                    instance.framework.progress_data['instances'].size.should == 3

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
                                    instance = instance_grid_spawn

                                    instance.service.scan(
                                        url:         web_server_url_for( :framework_simple ),
                                        audit_links: true,
                                        audit_forms: true,
                                        modules:     :test,
                                        spawns:      4,
                                        grid_mode:   :balance
                                    )

                                    # if a scan in already running it should just bail out early
                                    instance.service.scan.should be_false

                                    sleep 1 while instance.service.busy?

                                    # No matter how many grid members with unique Pipe-IDs there are
                                    # since we're in balance mode.
                                    instance.framework.progress_data['instances'].size.should == 5

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
                                    expect {
                                        instance_grid_spawn.service.scan(
                                            url:         web_server_url_for( :framework_simple ),
                                            audit_links: true,
                                            audit_forms: true,
                                            modules:     :test,
                                            spawns:      4,
                                            grid_mode:   :blahblah
                                        )
                                    }.to raise_error
                                end
                            end

                        end

                        context 'with :grid set to' do
                            context true do
                                it 'it a shorthand for grid_mode: :balance' do
                                    instance = instance_grid_spawn

                                    instance.service.scan(
                                        url:         web_server_url_for( :framework_simple ),
                                        audit_links: true,
                                        audit_forms: true,
                                        modules:     :test,
                                        spawns:      4,
                                        grid:        true
                                    )

                                    # if a scan in already running it should just bail out early
                                    instance.service.scan.should be_false

                                    sleep 1 while instance.service.busy?

                                    # No matter how many grid members with unique Pipe-IDs there are
                                    # since we're in balance mode.
                                    instance.framework.progress_data['instances'].size.should == 5

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
                                instance = instance_grid_spawn

                                raised = false
                                begin
                                    instance.service.scan(
                                        url:        web_server_url_for( :framework_simple ),
                                        grid_mode:  :balance
                                    )
                                rescue => e
                                    raised = e.rpc_exception?
                                end

                                raised.should be_true
                            end
                        end

                        context 'when Options#restrict_to_paths is set' do
                            it 'raises an exception' do
                                instance = instance_grid_spawn
                                url      = web_server_url_for( :framework_simple )

                                raised = false
                                begin
                                    instance.service.scan(
                                        url:            url,
                                        grid_mode:      :balance,
                                        spawns:         4,
                                        restrict_paths: [url]
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
                        instance = instance_spawn
                        instance.service.scan(
                            url:         web_server_url_for( :framework_simple ),
                            audit_links: true,
                            audit_forms: true,
                            modules:     :test,
                            spawns:      4
                        )
                        sleep 1 while instance.service.busy?

                        self_url = instance.framework.self_url

                        instance.service.progress( with: :instances )['instances'].each do |progress|
                            url = progress['url']
                            next if url == self_url
                            File.socket?( url ).should be_true
                        end
                    end

                    it 'spawns a number of slaves' do
                        instance = instance_spawn

                        instance.service.scan(
                            url:         web_server_url_for( :framework_simple ),
                            audit_links: true,
                            audit_forms: true,
                            modules:     :test,
                            spawns:      4
                        )

                        sleep 1 while instance.service.busy?

                        instance.framework.progress_data['instances'].size.should == 5

                        instance.service.busy?.should  == instance.framework.busy?
                        instance.service.status.should == instance.framework.status

                        i_report = instance.service.report
                        f_report = instance.framework.report

                        i_report.should == f_report
                        i_report['issues'].should be_any
                    end
                end

                context 'when link_count_limit has been set' do
                    it 'should be divided by the amount of spawns' do
                        instance = instance_spawn

                        link_count_limit = 100
                        spawns           = 4

                        instance.service.scan(
                            url:         web_server_url_for( :framework_simple ),
                            audit_links: true,
                            audit_forms: true,
                            modules:     :test,
                            spawns:      spawns,
                            link_count_limit: link_count_limit
                        )

                        instance.opts.link_count_limit.should == link_count_limit / (spawns + 1)
                    end
                end
                context 'when http_req_limit has been set' do
                    it 'should be divided by the amount of spawns' do
                        instance = instance_spawn

                        http_req_limit = 100
                        spawns         = 4

                        instance.service.scan(
                            url:         web_server_url_for( :framework_simple ),
                            audit_links: true,
                            audit_forms: true,
                            modules:     :test,
                            spawns:      spawns,
                            http_req_limit: http_req_limit
                        )

                        instance.opts.http_req_limit.should == http_req_limit / (spawns + 1)
                    end
                end
            end
        end

        describe '#progress' do
            before( :all ) do
                @progress_instance = instance_spawn
                @progress_instance.service.scan(
                    url:         web_server_url_for( :framework_simple ),
                    audit_links: true,
                    audit_forms: true,
                    modules:     :test,
                    spawns:      1
                )
                sleep 1 while @progress_instance.service.busy?
            end

            it 'returns progress information' do
                instance = @progress_instance

                p = instance.service.progress
                p['busy'].should   == instance.framework.busy?
                p['status'].should == instance.framework.status
                p['stats'].should  be_any

                p['instances'].should be_nil
                p['issues'].should be_nil
            end

            describe :without do
                describe :stats do
                    it 'includes stats' do
                        @progress_instance.service.progress( without: :stats )['stats'].should be_nil
                    end
                end
                describe :issues do
                    it 'does not include issues with the given Issue#digest hashes' do
                        p = @progress_instance.service.progress( with: :native_issues )
                        issue = p['issues'].first
                        digest = issue.digest

                        p = @progress_instance.service.
                                progress( with: :native_issues,
                                      without: { issues: [digest] }
                        )

                        p['issues'].include?( issue ).should be_false

                        p = @progress_instance.service.progress( with: :issues )
                        issue = p['issues'].first
                        digest = issue['digest']

                        p = @progress_instance.service.
                                progress( with: :issues,
                                      without: { issues: [digest] }
                        )

                        p['issues'].include?( issue ).should be_false
                    end
                end
                context 'with an array of things to be excluded'  do
                    it 'excludes those things' do
                        instance = @progress_instance

                        p = @progress_instance.service.progress( with: :native_issues )
                        issue = p['issues'].first
                        digest = issue.digest

                        p = instance.service.progress( with: [ :issues, :instances ], without: [ :stats,  issues: [digest] ] )
                        p['stats'].should  be_nil
                        p['issues'].include?( issue ).should be_false
                    end
                end
            end

            describe :with do
                describe :issues do
                    it 'includes issues' do
                        instance = @progress_instance

                        issues = instance.service.progress( with: :issues )['issues']
                        issues.should be_any
                        issues.first.class.should == Hash
                        issues.should == instance.framework.progress_data( as_hash: true )['issues']
                    end
                end

                describe :native_issues do
                    it 'includes issues as Arachni::Issue objects' do
                        instance = @progress_instance

                        issues = instance.service.progress( with: :native_issues )['issues']
                        issues.should be_any
                        issues.first.class.should == Arachni::Issue
                    end
                end

                describe :instances do
                    it 'includes instances' do
                        instance = @progress_instance

                        stats1 = instance.service.progress( with: :instances )['instances']
                        stats2 = instance.framework.progress_data['instances']

                        # Average req/s may differ.
                        stats1.each { |h| h.delete 'avg' }
                        stats2.each { |h| h.delete 'avg' }

                        stats1.size.should == 2
                        stats1.should == stats2
                    end
                end

                context 'with an array of things to be included'  do
                    it 'includes those things' do
                        instance = @progress_instance

                        p = instance.service.progress( with: [ :issues, :instances ], without: :stats )
                        p['busy'].should   == instance.framework.busy?
                        p['status'].should == instance.framework.status
                        p['stats'].should  be_nil

                        p['instances'].size.should == 2
                        p['issues'].should be_any
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
            @instance.framework.busy?.should be_false
        end
    end

    describe '#opts' do
        it 'provides access to the Options' do
            url = 'http://blah.com'
            @instance.opts.url = url
            @instance.opts.url.to_s.should == @utils.normalize_url( url )
        end
    end

    describe '#modules' do
        it 'provides access to the ModuleManager' do
            @instance.modules.available.sort.should == %w(test test2 test3).sort
        end
    end

    describe '#plugins' do
        it 'provides access to the PluginManager' do
            @instance.plugins.available.sort.should == %w(wait bad distributable loop default with_options spider_hook).sort
        end
    end
end
