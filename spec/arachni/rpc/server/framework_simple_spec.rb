require 'spec_helper'
require 'json'

describe 'Arachni::RPC::Server::Framework' do
    before( :all ) do
        @opts = Arachni::Options.instance

        @instance  = instance_spawn
        @framework = @instance.framework
        @modules   = @instance.modules
        @plugins   = @instance.plugins

        @instance_clean  = instance_spawn
        @framework_clean = @instance_clean.framework
    end

    describe '#errors' do
        context 'when no argument has been provided' do
            it 'returns all logged errors' do
                test = 'Test'
                @instance.framework.error_test test
                @instance.framework.errors.last.should end_with test
            end
        end
        context 'when a start line-range has been provided' do
            it 'returns all logged errors after that line' do
                initial_errors = @instance.framework.errors
                errors = @instance.framework.errors( 10 )

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
                @instance.opts.url = web_server_url_for( :auditor ) + '/sleep'
                @modules.load( 'test' )
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
            @framework_clean.master?.should be_false
        end
    end
    describe '#slave?' do
        it 'returns false' do
            @framework_clean.slave?.should be_false
        end
    end
    describe '#solo?' do
        it 'returns true' do
            @framework_clean.solo?.should be_true
        end
    end
    describe '#list_plugins' do
        it 'lists all available plugins' do
            plugins = @framework_clean.list_plugins
            plugins.size.should == 7
            plugin = plugins.select { |i| i[:name] =~ /default/i }.first
            plugin[:name].should == 'Default'
            plugin[:description].should == 'Some description'
            plugin[:author].size.should == 1
            plugin[:author].first.should == 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>'
            plugin[:version].should == '0.1'
            plugin[:plug_name].should == 'default'
            plugin[:options].size.should== 1
            opt = plugin[:options].first
            opt['name'].should == 'int_opt'
            opt['required'].should == false
            opt['desc'].should == 'An integer.'
            opt['default'].should == 4
            opt['enums'].should be_empty
            opt['type'].should == 'integer'
        end
        it 'aliased to #lsplug' do
            @framework_clean.list_plugins.should == @framework_clean.lsplug
        end
    end
    describe '#list_reports' do
        it 'lists all available plugins' do
            reports = @framework_clean.list_reports
            reports.should be_any
            report_with_opts = reports.select{ |r| r[:options].any? }.first
            report_with_opts[:options].first.should be_kind_of( Hash )
        end
        it 'aliased to #lsplug' do
            @framework_clean.list_reports.should == @framework_clean.lsrep
        end
    end

    describe '#list_modules' do
        it 'lists all available modules' do
            @framework_clean.list_modules.should be_any
        end
        it 'aliased to #lsmod' do
            @framework_clean.list_modules.should == @framework_clean.lsmod
        end
    end

    describe '#list_platforms' do
        it 'lists all available platforms' do
            @framework_clean.list_platforms.should == Arachni::Framework.new.list_platforms
        end
    end

    describe '#run' do
        it 'performs a scan' do
            instance = @instance_clean
            instance.opts.url = web_server_url_for( :framework_simple )
            instance.modules.load( 'test' )
            instance.framework.run.should be_true
            sleep( 1 ) while instance.framework.busy?
            instance.framework.issues.should be_any
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
            instance = @instance_clean
            instance.opts.url = web_server_url_for( :framework_simple )
            instance.modules.load( 'test' )
            instance.framework.run.should be_true

            stats = instance.framework.stats
            stat_keys = [
                :requests, :responses, :time_out_count,
                :time, :avg, :sitemap_size, :auditmap_size, :progress, :curr_res_time,
                :curr_res_cnt, :curr_avg, :average_res_time, :max_concurrency,
                :current_page, :eta
            ]
            stats.keys.should == stat_keys
            stat_keys.each { |k| stats[k].should be_true }
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
    describe '#status' do
        before( :all ) do
            @inst = instance_spawn
            @inst.opts.url = web_server_url_for( :framework_simple ) + '/crawl'
            @inst.modules.load( 'test' )
        end
        context 'after initialization' do
            it 'returns "ready"' do
                @inst.framework.status.should == 'ready'
            end
        end
        context 'after "run" has been called' do
            context 'and the scanner is crawling' do
                it 'returns "crawling"' do
                    @inst.framework.run.should be_true
                    sleep 2
                    @inst.framework.status.should == 'crawling'
                end
            end
            context 'and the scanner is paused' do
                it 'returns "paused"' do
                    @inst.framework.pause
                    @inst.framework.status.should == 'paused'
                    @inst.framework.resume
                end
            end
        end
        context 'during audit' do
            it 'returns "audit"' do
                mod_lib = @opts.dir['modules'].dup
                @opts.dir['modules'] = fixtures_path + '/wait_module/'

                inst = instance_spawn
                inst.opts.url = web_server_url_for( :framework_simple )
                inst.opts.audit_headers = true
                inst.modules.load( 'wait' )
                inst.framework.run
                sleep 2
                inst.framework.status.should == 'auditing'

                @opts.dir['modules'] = mod_lib.dup
            end
        end
        context 'once the scan had completed' do
            it 'returns "done"' do
                inst = instance_spawn
                inst.opts.url = web_server_url_for( :framework_simple )
                inst.modules.load( 'test' )
                inst.framework.run
                sleep 2
                inst.framework.status.should == 'done'
            end
        end
    end
    describe '#clean_up' do
        it 'sets the framework state to finished and wait for plugins to finish' do
            instance = instance_spawn
            instance.opts.url = web_server_url_for( :framework_hpg )
            instance.modules.load( 'test' )
            instance.plugins.load( { 'wait' => {} } )
            instance.framework.run.should be_true
            instance.framework.busy?.should be_true
            instance.framework.auditstore.plugins.should be_empty
            instance.framework.clean_up.should be_true
            results = instance.framework.auditstore.plugins
            results.should be_any
            results['wait'].should be_any
            results['wait'][:results].should == { stuff: true }
        end
    end
    describe '#progress' do
        before { @progress_keys = %W(stats status busy issues instances messages).sort }

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

                data['stats'].should be_any
                data['stats'].keys.should ==
                    instance.framework.stats.keys.map { |s| s.to_s }
                data['instances'].should be_empty
                data['status'].should be_true
                data['busy'].nil?.should be_false
                data['messages'].is_a?( Array ).should be_true
                data['issues'].should be_any
                data['instances'].should be_empty
                data.should_not include 'errors'
            end
        end

        context 'when called with option' do
            describe :errors do
                context 'when set to true' do
                    it 'includes all error messages' do
                        @instance_clean.framework.
                            progress( errors: true )['errors'].should be_empty

                        test = 'Test'
                        @instance_clean.framework.error_test test

                        @instance_clean.framework.
                            progress( errors: true )['errors'].last.
                            should end_with test
                    end
                end
                context 'when set to an Integer' do
                    it 'returns all logged errors after that line' do
                        @instance_clean.framework.error_test 'test'

                        initial_errors = @instance_clean.framework.
                            progress( errors: true )['errors']

                        errors = @instance_clean.framework.
                            progress( errors: 10 )['errors']

                        errors.should == initial_errors[10..-1]
                    end
                end
            end
            describe :messages do
                context 'when set to false' do
                    it 'excludes messages' do
                        keys = @instance_clean.framework.progress( messages: false ).
                            keys.sort
                        pk = @progress_keys.dup
                        pk.delete( "messages" )
                        keys.should == pk
                    end
                end
            end
            describe :issue do
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
            describe :as_hash do
                context 'when set to true' do
                    it 'includes issues as a hash' do
                        @instance_clean.framework.
                            progress( as_hash: true )['issues']
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

    describe '#self_url' do
        it 'returns the RPC URL' do
            @instance_clean.framework.self_url.should == @instance_clean.url
        end
    end

    describe '#token' do
        it 'returns the RPC token' do
            @instance_clean.framework.token.should == instance_token_for( @instance_clean )
        end
    end

    describe '#report_as' do
        context 'when passed a valid report name' do
            it 'returns the report as a string' do
                json = @instance_clean.framework.report_as( :json )
                JSON.load( json )['issues'].size.should == @instance_clean.framework.auditstore.issues.size
            end

            context 'which does not support the \'outfile\' option' do
                it 'raises an exception' do
                    expect { @instance_clean.framework.report_as( :stdout ) }.to raise_error
                end
            end
        end

        context 'when passed an invalid report name' do
            it 'raises an exception' do
                expect { @instance_clean.framework.report_as( :blah ) }.to raise_error
            end
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
            @instance_clean.framework.serialized_report.should ==
                @instance_clean.framework.report.to_yaml
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
        it 'restricts the audit to the provided element signatures' do
            mod_lib = @opts.dir['modules'].dup
            @opts.dir['modules'] = fixtures_path + '/taint_module/'

            inst = instance_spawn
            inst.opts.url = web_server_url_for( :framework_simple ) + '/restrict_to_elements'
            inst.opts.audit_links = true
            inst.modules.load( 'taint' )

            opts = { async: false, remove_id: true }
            res = Arachni::HTTP.instance.get( inst.opts.url.to_s, opts ).response

            link = Arachni::Element::Link.from_response( res ).pop
            inst.framework.restrict_to_elements(  [ link.scope_audit_id ] ).should be_true

            inst.framework.run.should be_true
            sleep 0.1 while inst.framework.busy?

            issues = inst.framework.issues
            issues.size.should == 1
            issues.first.var.should == link.auditable.keys.first
        end
    end
    describe '#update_page_queue' do
        it 'pushes the provided page objects to the page audit queue' do
            @opts.dir['modules'] = fixtures_path + '/taint_module/'
            url = web_server_url_for( :framework_simple )
            inst = instance_spawn
            inst.opts.url = url
            inst.opts.audit_links = true
            inst.modules.load( 'taint' )

            opts = { async: false, remove_id: true }
            url_to_audit = url +  '/restrict_to_elements'
            res = Arachni::HTTP.instance.get( url_to_audit, opts ).response

            page = Arachni::Page.from_response( res, @opts )
            inst.framework.update_page_queue( [ page ] ).should be_true

            inst.framework.run.should be_true
            sleep 0.1 while inst.framework.busy?

            inst.framework.issues.size.should == 2
        end
    end
    describe '#update_issues' do
        it 'registers an issue with the instance' do
            url = web_server_url_for( :framework_simple )
            inst = instance_spawn
            inst.opts.url = url

            issue = Arachni::Issue.new( name: 'stuff', url: url, elem: 'link' )
            inst.framework.update_issues( [issue] ).should be_true

            issues = inst.framework.issues
            issues.size.should == 1

            issue = issues.first
            issue.name.should == issue.name
            issue.var.should == issue.var
            issue.elem.should == issue.elem
        end
    end
end
