require 'spec_helper'

describe 'Arachni::RPC::Server::Framework' do
    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.dir['checks'] = fixtures_path + '/taint_check/'
        @opts.audit_links = true

        @instance  = instance_grid_spawn
        @framework = @instance.framework
        @checks    = @instance.checks
        @plugins   = @instance.plugins

        @instance_clean  = instance_grid_spawn
        @framework_clean = @instance_clean.framework

        @stat_keys = [
            :requests, :responses, :time_out_count, :time, :avg, :sitemap_size,
            :auditmap_size, :progress, :curr_res_time, :curr_res_cnt, :curr_avg,
            :average_res_time, :max_concurrency, :current_page, :eta
        ]
    end

    describe '#errors' do
        context 'when no argument has been provided' do
            it 'returns all logged errors' do
                test = 'Test'
                @framework.error_test test
                @framework.errors.last.should end_with test
            end
        end
        context 'when a start line-range has been provided' do
            it 'returns all logged errors after that line' do
                initial_errors = @framework.errors
                errors = @framework.errors( 10 )

                initial_errors[10..-1].should == errors
            end
        end
    end

    describe '#busy?' do
        context 'when the scan is not running' do
            it 'returns false' do
                @framework_clean.busy?.should be_false
            end
        end
        context 'when the scan is running' do
            it 'returns true' do
                @instance.opts.url = web_server_url_for( :auditor )
                @checks.load( 'taint' )
                @framework.run.should be_true
                @framework.busy?.should be_true
            end
        end
    end
    describe '#version' do
        it 'returns the system version' do
            @framework_clean.version.should == Arachni::VERSION
        end
    end
    describe '#revision' do
        it 'returns the framework revision' do
            @framework_clean.revision.should == Arachni::Framework::REVISION
        end
    end
    describe '#master?' do
        it 'returns false' do
            @framework_clean.master?.should be_true
        end
    end
    describe '#slave?' do
        it 'returns false' do
            @framework_clean.slave?.should be_false
        end
    end
    describe '#solo?' do
        it 'returns true' do
            @framework_clean.solo?.should be_false
        end
    end
    describe '#set_as_master' do
        it 'sets the instance as the master' do
            instance = instance_spawn
            instance.framework.master?.should be_false
            instance.framework.set_as_master
            instance.framework.master?.should be_true
        end
    end
    describe '#enslave' do
        it 'enslaves another instance and set itself as its master' do
            master = instance_spawn
            slave  = instance_spawn

            master.framework.master?.should be_false
            master.framework.enslave(
                'url'   => slave.url,
                'token' => instance_token_for( slave )
            )
            master.framework.master?.should be_true
        end
    end
    describe '#run' do
        context 'when Options#restrict_to_paths is set' do
            it 'fails with exception' do
                instance = instance_grid_spawn
                instance.opts.url = web_server_url_for( :framework_hpg )
                instance.opts.restrict_paths = [instance.opts.url]
                instance.checks.load( 'taint' )

                raised = false
                begin
                    instance.framework.run
                rescue Arachni::RPC::Exceptions::RemoteException
                    raised = true
                end
                raised.should be_true
            end
        end

        it 'performs a scan' do
            instance = @instance_clean
            instance.opts.url = web_server_url_for( :framework_hpg )
            instance.checks.load( 'taint' )
            instance.framework.run.should be_true
            sleep( 1 ) while instance.framework.busy?
            instance.framework.issues.size.should == 500
        end
    end
    describe '#auditstore' do
        it 'returns an auditstore object' do
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
        it 'returns a hash containing general runtime statistics' do
            stats = @instance_clean.framework.stats
            stats.keys.should == @stat_keys
            @stat_keys.each { |k| stats[k].should be_true }
        end
    end
    describe '#paused?' do
        context 'when not paused' do
            it 'returns false' do
                instance = @instance_clean
                instance.framework.paused?.should be_false
            end
        end
        context 'when paused' do
            it 'returns true' do
                instance = @instance_clean
                instance.framework.pause
                instance.framework.paused?.should be_true
            end
        end
    end
    describe '#resume' do
        it 'resumes the scan' do
            instance = @instance_clean
            instance.framework.pause
            instance.framework.paused?.should be_true
            instance.framework.resume.should be_true
            instance.framework.paused?.should be_false
        end
    end
    describe '#clean_up' do
        it 'sets the framework state to finished, waits for plugins to finish and merges their results' do
            instance = instance_grid_spawn
            instance.opts.url = web_server_url_for( :framework_hpg )
            instance.checks.load( 'taint' )
            instance.plugins.load( { 'wait' => {}, 'distributable' => {} } )
            instance.framework.run.should be_true
            instance.framework.auditstore.plugins.should be_empty
            instance.framework.busy?.should be_true
            instance.framework.clean_up.should be_true

            instance_count = instance.framework.progress['instances'].size
            auditstore     = instance.framework.auditstore
            instance.service.shutdown

            results = auditstore.plugins
            results.should be_any
            results['wait'].should be_any
            results['wait'][:results].should == { stuff: true }
            results['distributable'][:results].should == { stuff: instance_count }
        end
    end
    describe '#progress' do
        before { @progress_keys = %W(stats status busy issues instances).sort }

        it 'aliased to #progress_data' do
            instance = @instance_clean
            data = instance.framework.progress_data
            data.keys.sort.should == @progress_keys
        end

        context 'when called without options' do
            it 'returns all progress data' do
                instance = @instance_clean

                data = instance.framework.progress
                data.keys.sort.should == @progress_keys

                keys = (@stat_keys | %w(url status)).flatten.map { |k| k.to_s }.sort

                data['stats'].should be_any
                data['stats'].keys.sort.should == (keys | %w(current_pages)).flatten.sort
                data['instances'].should be_any
                data['status'].should be_true
                data['busy'].nil?.should be_false
                data['issues'].should be_any
                data['instances'].size.should == 3
                data.should_not include 'errors'

                keys = (keys | %w(current_page)).flatten.sort
                data['instances'].first.keys.sort.should == keys
                data['instances'].last.keys.sort.should == keys
            end
        end

        context 'when called with option' do
            describe :errors do
                context 'when set to true' do
                    it 'includes all error messages' do
                        instance = instance_grid_spawn
                        instance.framework.progress( errors: true )['errors'].should be_empty

                        test = 'Test'
                        instance.framework.error_test test

                        instance.framework.progress( errors: true )['errors'].last.should end_with test
                    end
                end
                context 'when set to an Integer' do
                    it 'returns all logged errors after that line per Instance' do
                        instance = instance_grid_spawn

                        100.times { instance.framework.error_test 'test' }

                        (instance.framework.progress( errors: true )['errors'].size -
                            instance.framework.progress( errors: 10 )['errors'].size).should == 10
                    end
                end
            end
            describe :stats do
                context 'when set to false' do
                    it 'excludes statistics' do
                        keys = @instance_clean.framework.progress( stats: false ).
                            keys.sort
                        pk = @progress_keys.dup
                        pk.delete( "stats" )
                        keys.should == pk
                    end
                end
            end
            describe :issues do
                context 'when set to false' do
                    it 'excludes issues' do
                        keys = @instance_clean.framework.progress( issues: false ).
                            keys.sort
                        pk = @progress_keys.dup
                        pk.delete( "issues" )
                        keys.should == pk
                    end
                end
            end
            describe :slaves do
                context 'when set to false' do
                    it 'excludes slave data' do
                        keys = @instance_clean.framework.progress( slaves: false ).
                            keys.sort
                        pk = @progress_keys.dup
                        pk.delete( "instances" )
                        keys.should == pk
                    end
                end
            end
            describe :as_hash do
                context 'when set to true' do
                    it 'includes issues as a hash' do
                        @instance_clean.framework
                            .progress( as_hash: true )['issues']
                        .first.is_a?( Hash ).should be_true
                    end
                end
            end
        end
    end
    describe '#report' do
        it 'returns a hash report of the scan' do
            report = @instance_clean.framework.report
            report.is_a?( Hash ).should be_true
            report['issues'].should be_any

            issue = report['issues'].first
            issue.is_a?( Hash ).should be_true
            issue['variations'].should be_any
            issue['variations'].first.is_a?( Hash ).should be_true
        end

        it 'aliased to #audit_store_as_hash' do
            @instance_clean.framework.report.should ==
                @instance_clean.framework.audit_store_as_hash
        end
        it 'aliased to #auditstore_as_hash' do
            @instance_clean.framework.report.should ==
                @instance_clean.framework.auditstore_as_hash
        end
    end
    describe '#serialized_auditstore' do
        it 'returns a YAML serialized AuditStore' do
            yaml_str = @instance_clean.framework.serialized_auditstore
            YAML.load( yaml_str ).is_a?( Arachni::AuditStore ).should be_true
        end
    end
    describe '#serialized_report' do
        it 'returns a YAML serialized report hash' do
            YAML.load( @instance_clean.framework.serialized_report ).should ==
                @instance_clean.framework.report
        end
    end
    describe '#issues' do
        it 'returns an array of issues without variations' do
            issues = @instance_clean.framework.issues
            issues.should be_any

            issue = issues.first
            issue.is_a?( Arachni::Issue ).should be_true
            issue.variations.should be_empty
        end
    end
    describe '#issues_as_hash' do
        it 'returns an array of issues (as hash) without variations' do
            issues = @instance_clean.framework.issues_as_hash
            issues.should be_any

            issue = issues.first
            issue.is_a?( Hash ).should be_true
            issue['variations'].should be_empty
        end
    end

    describe '#restrict_to_elements' do
        it 'returns false' do
            @instance_clean.framework.restrict_to_elements( [] ).should be_false
        end
    end
    describe '#update_page_queue' do
        it 'returns false' do
            @instance_clean.framework.update_page_queue( [] ).should be_false
        end
    end
    describe '#update_issues' do
        it 'returns false' do
            @instance_clean.framework.update_issues( [] ).should be_false
        end
    end
end
