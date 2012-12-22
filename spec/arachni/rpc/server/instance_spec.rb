require_relative '../../../spec_helper'

require Arachni::Options.instance.dir['lib'] + 'rpc/server/dispatcher'
require Arachni::Options.instance.dir['lib'] + 'rpc/client/instance'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/instance'

describe Arachni::RPC::Server::Instance do
    before( :all ) do
        @opts = Arachni::Options.instance
        @token = 'secret!'

        @instances = []

        @get_instance = proc do |opts|
            opts ||= @opts

            port = random_port
            opts.rpc_port = port

            fork_em { Arachni::RPC::Server::Instance.new( opts, @token ) }
            sleep 1

            @instances << Arachni::RPC::Client::Instance.new( opts,
                "#{opts.rpc_address}:#{port}", @token
            )

            @instances.last
        end

        @utils = Arachni::Module::Utilities
        @instance = @get_instance.call

        @dispatchers = []

        @opts.pool_size = 1
        @get_grid_instance = proc do |opts|
            opts ||= @opts
            port = random_port
            opts.rpc_port = port
            exec_dispatcher( opts )

            port2 =  random_port
            opts.rpc_port = port2
            opts.neighbour = "#{opts.rpc_address}:#{port}"
            opts.pipe_id = 'blah'
            exec_dispatcher( opts )

            dispatcher = Arachni::RPC::Client::Dispatcher.new( opts,
                                                               "#{opts.rpc_address}:#{port}" )
            @dispatchers << dispatcher

            inst_info = dispatcher.dispatch
            @instances << Arachni::RPC::Client::Instance.new( opts,inst_info['url'], inst_info['token'] )
            @instances.last
        end
    end

    after( :all ) do
        @instances.each { |i| i.service.shutdown rescue nil }
        @dispatchers.each { |d| d.stats['consumed_pids'].each { |p| pids << p } }
    end

    describe '#service' do
        describe '#alive?' do
            it 'should return true' do
                @instance.service.alive?.should == true
            end
        end

        describe '#paused?' do
            context 'when not paused' do
                it 'should return false' do
                    @instance.framework.paused?.should be_false
                end
            end
            context 'when paused' do
                it 'should return true' do
                    @instance.framework.pause
                    @instance.framework.paused?.should be_true
                end
            end
        end
        describe '#resume' do
            it 'should resume the scan' do
                @instance.framework.pause
                @instance.framework.paused?.should be_true
                @instance.framework.resume.should be_true
                @instance.framework.paused?.should be_false
            end
        end

        describe '#busy?' do
            it 'should delegate to Framework' do
                @instance.service.busy?.should == @instance.framework.busy?
            end
        end

        describe '#report' do
            it 'should delegate to Framework' do
                @instance.service.report.should == @instance.framework.report
            end
        end

        describe '#abort_and_report' do
            describe 'nil' do
                it 'should cleanup and return the report as a Hash' do
                    @instance.service.abort_and_report.should == @instance.framework.report
                end
            end

            describe :auditstore do
                it 'should delegate to Framework' do
                    @instance.service.abort_and_report( :auditstore ).should == @instance.framework.auditstore
                end
            end
        end

        describe '#abort_and_report_as' do
            it 'should cleanup and delegate to #report_as' do
                Nokogiri::HTML( @instance.service.abort_and_report_as( :html ) ).title.should be_true
            end
        end

        describe '#report_as' do
            it 'should delegate to Framework' do
                Nokogiri::HTML( @instance.service.report_as( :html ) ).title.should be_true
            end
        end

        describe '#status' do
            it 'should delegate to Framework' do
                @instance.service.status.should == @instance.framework.status
            end
        end

        describe '#output' do
            it 'should delegate to Framework' do
                @instance.service.output.should be_any
            end
        end

        describe '#scan' do
            it 'should configure and start a scan' do
                instance = @get_instance.call

                slave = @get_instance.call

                instance.service.busy?.should  == instance.framework.busy?
                instance.service.status.should == instance.framework.status

                instance.service.scan(
                    url:         server_url_for( :framework_simple ),
                    audit_links: true,
                    audit_forms: true,
                    modules:     :test,
                    slaves:      [ { url: slave.url, token: @token } ]
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

            describe :spawns do
                context 'when it has a Dispatcher who is a Grid member' do
                    it 'should request its slaves from it' do
                        instance = @get_grid_instance.call

                        instance.service.scan(
                            url:         server_url_for( :framework_simple ),
                            audit_links: true,
                            audit_forms: true,
                            modules:     :test,
                            spawns:      4,
                            grid:        true
                        )

                        # if a scan in already running it should just bail out early
                        instance.service.scan.should be_false

                        sleep 1 while instance.service.busy?

                        # Since we've only got 2 Dispatchers in the Grid.
                        instance.framework.progress_data['instances'].size.should == 2

                        instance.service.busy?.should  == instance.framework.busy?
                        instance.service.status.should == instance.framework.status

                        i_report = instance.service.report
                        f_report = instance.framework.report

                        i_report.should == f_report
                        i_report['issues'].should be_any
                    end
                end
                context 'when it has a Dispatcher' do
                    it 'should request its slaves from it' do
                        instance = @get_grid_instance.call

                        instance.service.scan(
                            url:         server_url_for( :framework_simple ),
                            audit_links: true,
                            audit_forms: true,
                            modules:     :test,
                            spawns:      4
                        )

                        # if a scan in already running it should just bail out early
                        instance.service.scan.should be_false

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
                context 'when it does not have a Dispatcher' do
                    it 'should spawn a number of slaves' do
                        instance = @get_instance.call

                        instance.service.scan(
                            url:         server_url_for( :framework_simple ),
                            audit_links: true,
                            audit_forms: true,
                            modules:     :test,
                            spawns:      4
                        )

                        # if a scan in already running it should just bail out early
                        instance.service.scan.should be_false

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
            end
        end

        describe '#progress' do
            before( :all ) do
                @progress_instance = @get_instance.call
                @progress_instance.service.scan(
                    url:         server_url_for( :framework_simple ),
                    audit_links: true,
                    audit_forms: true,
                    modules:     :test,
                    spawns:      1
                )
                sleep 1 while @progress_instance.service.busy?
            end

            it 'should return progress information' do
                instance = @progress_instance

                p = instance.service.progress
                p['busy'].should   == instance.framework.busy?
                p['status'].should == instance.framework.status
                p['stats'].should  be_any

                p['instances'].should be_nil
                p['messages'].should be_nil
                p['issues'].should be_nil
            end

            describe :without do
                describe :stats do
                    it 'should not include stats' do
                        @progress_instance.service.progress( without: :stats )['stats'].should be_nil
                    end
                end
                describe :issues do
                    it 'should not include issues with the given Issue#digest hashes' do
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
                    it 'should include those things' do
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
                    it 'should include issues' do
                        instance = @progress_instance

                        issues = instance.service.progress( with: :issues )['issues']
                        issues.should be_any
                        issues.first.class.should == Hash
                        issues.should == instance.framework.progress_data( as_hash: true )['issues']
                    end
                end

                describe :native_issues do
                    it 'should include issues as Arachni::Issue objects' do
                        instance = @progress_instance

                        issues = instance.service.progress( with: :native_issues )['issues']
                        issues.should be_any
                        issues.first.class.should == Arachni::Issue
                    end
                end

                describe :instances do
                    it 'should include instances' do
                        instance = @progress_instance
                        p = instance.service.progress( with: :instances )
                        p['instances'].size.should == 2
                        p['instances'].should == instance.framework.progress_data['instances']
                    end
                end

                context 'with an array of things to be included'  do
                    it 'should include those things' do
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
            it 'should shutdown the instance' do
                instance = @get_instance.call
                instance.service.shutdown.should be_true
                sleep 4
                raised = false
                begin
                    instance.service.alive?
                rescue Exception
                    raised = true
                end

                raised.should be_true
            end
        end
    end

    describe '#framework' do
        it 'should provide access to the framework' do
            @instance.framework.busy?.should be_false
        end
    end

    describe '#opts' do
        it 'should provide access to the options' do
            url = 'http://blah.com'
            @instance.opts.url = url
            @instance.opts.url.to_s.should == @utils.normalize_url( url )
        end
    end

    describe '#modules' do
        it 'should provide access to the module manager' do
            @instance.modules.available.sort.should == %w(test test2 test3).sort
        end
    end

    describe '#plugins' do
        it 'should provide access to the plugin manager' do
            @instance.plugins.available.sort.should == %w(wait bad distributable loop default with_options spider_hook).sort
        end
    end
end
