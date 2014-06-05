require 'spec_helper'

describe 'Arachni::RPC::Server::Framework' do
    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.paths.checks = fixtures_path + '/taint_check/'
        @opts.audit.elements :links, :forms, :cookies

        @instance  = instance_light_grid_spawn
        @framework = @instance.framework
        @checks    = @instance.checks
        @plugins   = @instance.plugins

        @instance_clean  = instance_light_grid_spawn
        @framework_clean = @instance_clean.framework

        @statistics_keys = [:http, :found_pages, :audited_pages, :runtime]
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
                @instance.options.url = web_server_url_for( :auditor )
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

            instance_kill instance.url
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

            instance_kill master.url
        end
    end
    describe '#run' do
        it 'performs a scan' do
            instance = @instance_clean
            instance.options.url = web_server_url_for( :framework_multi )
            instance.checks.load( 'taint' )
            instance.framework.run.should be_true
            sleep( 1 ) while instance.framework.busy?
            instance.framework.issues.size.should == 500
        end

        it 'handles pages with JavaScript code' do
            instance = instance_light_grid_spawn
            instance.options.url = web_server_url_for( :auditor ) + '/with_javascript'
            instance.checks.load :taint

            instance.framework.run.should be_true
            sleep 0.1 while instance.framework.busy?

            instance.framework.issues.
                map { |i| i.vector.affected_input_name }.uniq.should be
                    %w(link_input form_input cookie_input)

            # dispatcher_kill_by_instance instance
        end

        it 'handles AJAX' do
            instance = instance_light_grid_spawn
            instance.options.url = web_server_url_for( :auditor ) + '/with_ajax'
            instance.checks.load :taint

            instance.framework.run.should be_true
            sleep 0.1 while instance.framework.busy?

            instance.framework.issues.
                map { |i| i.vector.affected_input_name }.uniq.should be
                    %w(link_input form_input cookie_taint).sort

            # dispatcher_kill_by_instance instance
        end
    end
    describe '#auditstore' do
        it 'returns an auditstore object' do
            auditstore = @instance_clean.framework.auditstore
            auditstore.is_a?( Arachni::AuditStore ).should be_true
            auditstore.issues.should be_any
        end
    end
    describe '#statistics' do
        it 'returns a hash containing general runtime statistics' do
            statistics = @instance_clean.framework.statistics

            keys = @statistics_keys | [:current_page]

            statistics.keys.sort.should == keys.sort
            keys.each { |k| statistics[k].should be_true }
        end
    end
    describe '#clean_up' do
        it 'sets the framework state to finished, waits for plugins to finish and merges their results' do
            @instance = instance = instance_light_grid_spawn
            instance.options.url = web_server_url_for( :framework_multi )
            instance.checks.load( 'taint' )
            instance.plugins.load( { 'wait' => {}, 'distributable' => {} } )
            instance.framework.run.should be_true
            instance.framework.auditstore.plugins.should be_empty

            # Wait till the slaves join the scan.
            sleep 0.1 while instance.framework.progress[:instances].size != 3

            instance.framework.clean_up.should be_true

            instance_count = instance.framework.progress[:instances].size
            auditstore     = instance.framework.auditstore

            results = auditstore.plugins
            results.should be_any
            results[:wait].should be_any
            results[:wait][:results].should == { 'stuff' => true }
            results[:distributable][:results].should == { 'stuff' => instance_count }

            # dispatcher_kill_by_instance instance
        end
    end
    describe '#progress' do
        before { @progress_keys = %W(statistics status busy issues instances).map(&:to_sym).sort }

        context 'when called without options' do
            it 'returns all progress data' do
                instance = @instance_clean

                data = instance.framework.progress

                data.keys.sort.should == (@progress_keys | [:master]).flatten.sort

                data[:statistics].keys.sort.should ==
                    (@statistics_keys | [:current_pages]).flatten.sort

                data[:status].should be_kind_of Symbol
                data[:master].should == instance.url
                data[:busy].should_not be_nil
                data[:issues].should be_any
                data[:instances].size.should == 3

                data.should_not include :errors

                keys = (@statistics_keys | [:current_page]).flatten.sort

                data[:instances].each do |i|
                    i[:statistics].keys.sort.should == keys
                    i.keys.sort.should == [:url, :statistics, :status, :busy, :messages].sort
                end

                data.delete :issues
            end
        end

        context 'when called with option' do
            describe :errors do
                context 'when set to true' do
                    it 'includes all error messages' do
                        instance = instance_light_grid_spawn
                        instance.framework.progress( errors: true )[:errors].should be_empty

                        test = 'Test'
                        instance.framework.error_test test

                        instance.framework.progress( errors: true )[:errors].last.should end_with test

                        # dispatcher_kill_by_instance instance
                    end
                end
                context 'when set to an Integer' do
                    it 'returns all logged errors after that line per Instance' do
                        instance = instance_light_grid_spawn

                        100.times { instance.framework.error_test 'test' }

                        (instance.framework.progress( errors: true )[:errors].size -
                            instance.framework.progress( errors: 10 )[:errors].size).should == 10

                        # dispatcher_kill_by_instance instance
                    end
                end
            end

            describe :sitemap do
                context 'when set to true' do
                    it 'returns entire sitemap' do
                        @instance_clean.framework.
                            progress( sitemap: true )[:sitemap].should ==
                                @instance_clean.framework.sitemap
                    end
                end

                context 'when an index has been provided' do
                    it 'returns all entries after that line' do
                        @instance_clean.framework.progress( sitemap: 10 )[:sitemap].should ==
                            @instance_clean.framework.sitemap_entries( 10 )
                    end
                end
            end

            describe :statistics do
                context 'when set to false' do
                    it 'excludes statistics' do
                        @instance_clean.framework.progress(
                            statistics: false
                        ).should_not include :statistics
                    end
                end
            end
            describe :issues do
                context 'when set to false' do
                    it 'excludes issues' do
                        @instance_clean.framework.progress(
                            issues: false
                        ).should_not include :issues
                    end
                end
            end
            describe :slaves do
                context 'when set to false' do
                    it 'excludes slave data' do
                        @instance_clean.framework.progress(
                            slaves: false
                        ).should_not include :instances
                    end
                end
            end
            describe :as_hash do
                context 'when set to true' do
                    it 'includes issues as a hash' do
                        @instance_clean.framework.
                            progress( as_hash: true )[:issues].
                                first.is_a?( Hash ).should be_true
                    end
                end
            end
        end
    end

    describe '#sitemap_entries' do
        context 'when no argument has been provided' do
            it 'returns entire sitemap' do
                @instance_clean.framework.sitemap_entries.should ==
                    @instance_clean.framework.sitemap
            end
        end

        context 'when an index has been provided' do
            it 'returns all entries after that line' do
                sitemap = @instance_clean.framework.sitemap
                @instance_clean.framework.sitemap_entries( 10 ).should ==
                    Hash[sitemap.to_a[10..-1]]
            end
        end
    end

    describe '#report' do
        it 'returns a hash report of the scan' do
            report = @instance_clean.framework.report
            report.is_a?( Hash ).should be_true
            report['issues'].should be_any
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
end
