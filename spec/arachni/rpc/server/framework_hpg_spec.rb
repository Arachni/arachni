require_relative '../../../spec_helper'

require Arachni::Options.instance.dir['lib'] + 'rpc/client/dispatcher'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/dispatcher'

describe Arachni::RPC::Server::Framework do
    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.audit_links = true

        @dispatchers = []

        @opts.pool_size = 1
        @get_instance = proc do |opts|
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

            inst_info = dispatcher.dispatch
            inst = Arachni::RPC::Client::Instance.new( opts,
                inst_info['url'], inst_info['token']
            )
            inst.opts.grid_mode = 'high_performance'
            inst
        end

        @instance = @get_instance.call
        @framework = @instance.framework
        @modules = @instance.modules
        @plugins = @instance.plugins

        @instance_clean = @get_instance.call
        @framework_clean = @instance_clean.framework

        @stat_keys = [
            :requests, :responses, :time_out_count,
            :time, :avg, :sitemap_size, :auditmap_size, :progress, :curr_res_time,
            :curr_res_cnt, :curr_avg, :average_res_time, :max_concurrency,
            :current_page, :eta,
        ]

    end

    describe '#busy?' do
        context 'when the scan is not running' do
            it 'should return false' do
                @framework_clean.busy?.should be_false
            end
        end
        context 'when the scan is running' do
            it 'should return true' do
                @instance.opts.url = server_url_for( :auditor )
                @modules.load( 'test' )
                @framework.run.should be_true
                @framework.busy?.should be_true
            end
        end
    end
    describe '#version' do
        it 'should return the system version' do
            @framework_clean.version.should == Arachni::VERSION
        end
    end
    describe '#revision' do
        it 'should return the framework revision' do
            @framework_clean.revision.should == Arachni::Framework::REVISION
        end
    end
    describe '#high_performance?' do
        it 'should return true' do
            @framework_clean.high_performance?.should be_true
        end
    end
    describe '#output' do
        it 'should return the instance\'s output messages' do
            output = @framework_clean.output.first
            output.keys.first.is_a?( Symbol ).should be_true
            output.values.first.is_a?( String ).should be_true
        end
    end
    describe '#run' do
        it 'should perform a scan' do
            instance = @instance_clean
            instance.opts.url = server_url_for( :framework_hpg )
            instance.modules.load( 'test' )
            instance.framework.run.should be_true
            sleep( 1 ) while instance.framework.busy?
            instance.framework.issues.should be_any
        end
    end
    describe '#auditstore' do
        it 'should return an auditstore object' do
            auditstore = @instance_clean.framework.auditstore
            auditstore.is_a?( Arachni::AuditStore ).should be_true
            auditstore.issues.should be_any
            issue = auditstore.issues.first
            issue.is_a?( Arachni::Issue ).should be_true
            issue.variations.should be_any
            issue.variations.first.is_a?( Arachni::Issue ).should be_true
        end
    end
    describe '#stats' do
        it 'should return a hash containing general runtime statistics' do
            instance = @instance_clean
            instance.opts.url = server_url_for( :framework_hpg )
            instance.modules.load( 'test' )
            instance.framework.run.should be_true

            stats = instance.framework.stats
            stats.keys.should == @stat_keys
            @stat_keys.each { |k| stats[k].should be_true }
        end
    end
    describe '#paused?' do
        context 'when not paused' do
            it 'should return false' do
                instance = @instance_clean
                instance.framework.paused?.should be_false
            end
        end
        context 'when paused' do
            it 'should return true' do
                instance = @instance_clean
                instance.framework.pause
                instance.framework.paused?.should be_true
            end
        end
    end
    describe '#resume' do
        it 'should resume the scan' do
            instance = @instance_clean
            instance.framework.pause
            instance.framework.paused?.should be_true
            instance.framework.resume.should be_true
            instance.framework.paused?.should be_false
        end
    end
    describe '#clean_up' do
        it 'should set the framework state to finished, wait for plugins to finish and merge their results' do
            instance = @get_instance.call
            instance.opts.url = server_url_for( :framework_hpg )
            instance.modules.load( 'test' )
            instance.plugins.load( { 'wait' => {}, 'distributable' => {} } )
            instance.framework.run.should be_true
            instance.framework.auditstore.plugins.should be_empty
            instance.framework.busy?.should be_true

            tries = 4
            begin
                sleep( 1 ) while instance.framework.busy?
            rescue Exception
                tries -= 1
                retry if tries > 0
            end

            instance.framework.clean_up.should be_true
            results = instance.framework.auditstore.plugins
            results.should be_any
            results['wait'].should be_any
            results['wait'][:results].should == { stuff: true }
            results['distributable'][:results].should == { stuff: 2 }
        end
    end
    describe '#progress' do
        before { @progress_keys = %W(stats status busy issues instances messages).sort }

        it 'should be aliased to #progress_data' do
            instance = @instance_clean
            data = instance.framework.progress_data
            data.keys.sort.should == @progress_keys
        end

        context 'when called without options' do
            it 'should return all progress data' do
                instance = @instance_clean

                data = instance.framework.progress
                data.keys.sort.should == @progress_keys

                keys = (@stat_keys | %w(url status)).flatten.map { |k| k.to_s }.sort

                data['stats'].should be_any
                data['stats'].keys.sort.should == (keys | %w(current_pages)).flatten.sort
                data['instances'].should be_any
                data['status'].should be_true
                data['busy'].nil?.should be_false
                data['messages'].is_a?( Array ).should be_true
                data['issues'].should be_any
                data['instances'].size.should == 2

                keys = (keys | %w(current_page)).flatten.sort
                data['instances'].first.keys.sort.should == keys
                data['instances'].last.keys.sort.should == keys
            end
        end

        context 'when called with option' do
            describe :messages do
                context 'when set to false' do
                    it 'should exclude messages' do
                        keys = @instance_clean.framework. progress( messages: false ).
                            keys.sort
                        pk = @progress_keys.dup
                        pk.delete( "messages" )
                        keys.should == pk
                    end
                end
            end
            describe :issues do
                context 'when set to false' do
                    it 'should exclude issues' do
                        keys = @instance_clean.framework. progress( issues: false ).
                            keys.sort
                        pk = @progress_keys.dup
                        pk.delete( "issues" )
                        keys.should == pk
                    end
                end
            end
            describe :slaves do
                context 'when set to false' do
                    it 'should exclude issues' do
                        keys = @instance_clean.framework. progress( slaves: false ).
                            keys.sort
                        pk = @progress_keys.dup
                        pk.delete( "instances" )
                        keys.should == pk
                    end
                end
            end
            describe :as_hash do
                context 'when set to true' do
                    it 'should include issues as a hash' do
                        @instance_clean.framework
                            .progress( as_hash: true )['issues']
                        .first.is_a?( Hash ).should be_true
                    end
                end
            end
        end
    end
    describe '#report' do
        it 'should return a hash report of the scan' do
            report = @instance_clean.framework.report
            report.is_a?( Hash ).should be_true
            report['issues'].should be_any

            issue = report['issues'].first
            issue.is_a?( Hash ).should be_true
            issue['variations'].should be_any
            issue['variations'].first.is_a?( Hash ).should be_true
        end

        it 'should be aliased to #audit_store_as_hash' do
            @instance_clean.framework.report.should ==
                @instance_clean.framework.audit_store_as_hash
        end
        it 'should be aliased to #auditstore_as_hash' do
            @instance_clean.framework.report.should ==
                @instance_clean.framework.auditstore_as_hash
        end
    end
    describe '#serialized_auditstore' do
        it 'should return a YAML serialized AuditStore' do
            yaml_str = @instance_clean.framework.serialized_auditstore
            YAML.load( yaml_str ).is_a?( Arachni::AuditStore ).should be_true
        end
    end
    describe '#serialized_report' do
        it 'should return a YAML serialized report hash' do
            yaml_str = @instance_clean.framework.serialized_report
            YAML.load( yaml_str ).should == @instance_clean.framework.report
        end
    end
    describe '#issues' do
        it 'should return an array of issues without variations' do
            issues = @instance_clean.framework.issues
            issues.should be_any

            issue = issues.first
            issue.is_a?( Arachni::Issue ).should be_true
            issue.variations.should be_empty
        end
    end
    describe '#issues_as_hash' do
        it 'should return an array of issues (as hash) without variations' do
            issues = @instance_clean.framework.issues_as_hash
            issues.should be_any

            issue = issues.first
            issue.is_a?( Hash ).should be_true
            issue['variations'].should be_empty
        end
    end

    describe '#restrict_to_elements' do
        it 'should return false' do
            @instance_clean.framework.restrict_to_elements( [] ).should be_false
        end
    end
    describe '#update_page_queue' do
        it 'should return false' do
            @instance_clean.framework.update_page_queue( [] ).should be_false
        end
    end
    describe '#register_issues' do
        it 'should return false' do
            @instance_clean.framework.register_issues( [] ).should be_false
        end
    end
end
