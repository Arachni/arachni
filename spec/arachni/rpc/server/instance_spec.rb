require_relative '../../../spec_helper'

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
    end

    after( :all ){ @instances.each { |i| i.service.shutdown rescue nil } }

    describe '#service' do
        describe '#alive?' do
            it 'should return true' do
                @instance.service.alive?.should == true
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
                it 'should instruct the Instance to spawn a number of slaves' do
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

        describe '#progress' do
            it 'should return progress information' do
                instance = @get_instance.call

                slave = @get_instance.call

                p = instance.service.progress

                p['busy'].should   == instance.framework.busy?
                p['status'].should == instance.framework.status
                p['stats'].should  == instance.framework.progress['stats']

                p['instances'].should be_nil
                p['messages'].should be_nil
                p['issues'].should be_nil

                instance.service.progress( :with_issues )['issues'].should be_empty

                instance.service.scan(
                    url:         server_url_for( :framework_simple ),
                    audit_links: true,
                    audit_forms: true,
                    modules:     :test,
                    slaves:      [ { url: slave.url, token: @token } ]
                )

                sleep 1 while instance.service.busy?

                p = instance.service.progress

                p['busy'].should   == instance.framework.busy?
                p['status'].should == instance.framework.status
                p['stats'].keys.should  == instance.framework.progress['stats'].keys

                p['instances'].should be_nil

                p = instance.service.progress( :with_instances )
                p['instances'].size.should == 2
                p['instances'].should == instance.framework.progress_data['instances']

                p['messages'].should be_nil

                issues = instance.service.progress( :with_issues )['issues']
                issues.should be_any
                issues.should == instance.framework.progress_data( as_hash: true )['issues']
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
