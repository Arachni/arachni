require 'spec_helper'
require 'json'

describe 'Arachni::RPC::Server::Framework' do
    before( :all ) do
        @opts = Arachni::Options.instance

        @instance  = instance_spawn
        @framework = @instance.framework
        @checks    = @instance.checks
        @plugins   = @instance.plugins

        @instance_clean  = instance_spawn
        @framework_clean = @instance_clean.framework
    end
    before( :each ) { reset_options }

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
                @instance.options.url = web_server_url_for( :auditor ) + '/sleep'
                @checks.load( 'test' )
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
            plugin[:shortname].should == 'default'
            plugin[:options].size.should== 1

            opt = plugin[:options].first
            opt[:name].should == :int_opt
            opt[:required].should == false
            opt[:description].should == 'An integer.'
            opt[:default].should == 4
            opt[:type].should == :integer
        end
    end
    describe '#list_reports' do
        it 'lists all available reports' do
            reports = @framework_clean.list_reports
            reports.should be_any
            report_with_opts = reports.select{ |r| r[:options].any? }.first
            report_with_opts[:options].first.should be_kind_of( Hash )
        end
        it 'aliased to #list_reports' do
            @framework_clean.list_reports.should == @framework_clean.list_reports
        end
    end

    describe '#list_checks' do
        it 'lists all available checks' do
            @framework_clean.list_checks.should be_any
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
            instance.options.url = web_server_url_for( :framework )
            instance.checks.load( 'test' )
            instance.framework.run
            sleep( 1 ) while instance.framework.busy?
            instance.framework.issues.should be_any
        end

        it 'handles pages with JavaScript code' do
            @opts.paths.checks = fixtures_path + '/taint_check/'

            instance = instance_spawn
            instance.options.url = web_server_url_for( :auditor ) + '/with_javascript'
            instance.options.set audit: { elements: [:links, :forms, :cookies] }
            instance.checks.load :taint

            instance.framework.run
            sleep 0.1 while instance.framework.busy?

            instance.framework.issues.
                map { |i| i.vector.affected_input_name }.uniq.should be
                %w(link_input form_input cookie_input).sort
        end

        it 'handles AJAX' do
            @opts.paths.checks = fixtures_path + '/taint_check/'

            instance = instance_spawn
            instance.options.url = web_server_url_for( :auditor ) + '/with_ajax'
            instance.options.set audit: { elements: [:links, :forms, :cookies] }
            instance.checks.load :taint

            instance.framework.run
            sleep 0.1 while instance.framework.busy?

            instance.framework.issues.
                map { |i| i.vector.affected_input_name }.uniq.should be
                %w(link_input form_input cookie_taint).sort
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
            instance = @instance_clean
            instance.options.url = web_server_url_for( :framework )
            instance.checks.load( 'test' )
            instance.framework.run.should be_true

            instance.framework.statistics.should be_kind_of Hash
        end
    end
    describe '#status' do
        before( :all ) do
            @instance = instance_spawn
            @instance.options.url = web_server_url_for( :framework ) + '/crawl'
            @instance.checks.load( 'test' )
        end
        context 'after initialization' do
            it 'returns :ready' do
                @instance.framework.status.should == :ready
            end
        end
        context 'after #run has been called' do
            it 'returns :scanning' do
                @instance.framework.run.should be_true
                sleep 2
                @instance.framework.status.should == :scanning
            end
        end
        context 'once the scan had completed' do
            it 'returns :done' do
                instance = instance_spawn
                instance.options.url = web_server_url_for( :framework )
                instance.checks.load( 'test' )
                instance.framework.run
                sleep 1 while instance.framework.busy?
                instance.framework.status.should == :done
            end
        end
    end
    describe '#clean_up' do
        it 'sets the framework state to finished and wait for plugins to finish' do
            instance = instance_spawn
            instance.options.url = web_server_url_for( :framework_multi )
            instance.checks.load( 'test' )
            instance.plugins.load( { 'wait' => {} } )
            instance.framework.run.should be_true
            instance.framework.busy?.should be_true
            instance.framework.auditstore.plugins.should be_empty
            instance.framework.clean_up.should be_true
            results = instance.framework.auditstore.plugins
            results.should be_any
            results[:wait].should be_any
            results[:wait][:results].should == { 'stuff' => true }
        end
    end
    describe '#progress' do
        before { @progress_keys = %W(statistics status busy messages issues).sort.map(&:to_sym) }

        context 'when called without options' do
            it 'returns all progress data' do
                instance = @instance_clean

                data = instance.framework.progress
                data.keys.sort.should == @progress_keys

                data[:statistics].keys.should == instance.framework.statistics.keys
                data[:messages].should be_any
                data[:status].should be_true
                data[:busy].nil?.should be_false
                data[:issues].should be_any
                data.should_not include :errors
            end
        end

        context 'when called with option' do
            describe :errors do
                context 'when set to true' do
                    it 'includes all error messages' do
                        @instance_clean.framework.
                            progress( errors: true )[:errors].should be_empty

                        test = 'Test'
                        @instance_clean.framework.error_test test

                        @instance_clean.framework.
                            progress( errors: true )[:errors].last.
                                should end_with test
                    end
                end
                context 'when set to an Integer' do
                    it 'returns all logged errors after that line' do
                        @instance_clean.framework.error_test 'test'

                        initial_errors = @instance_clean.framework.
                            progress( errors: true )[:errors]

                        errors = @instance_clean.framework.
                            progress( errors: 10 )[:errors]

                        errors.should == initial_errors[10..-1]
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
                        instance = instance_spawn
                        instance.options.set(
                            url: web_server_url_for( :framework_multi ),
                            scope: {
                                page_limit: 50
                            }
                        )
                        instance.framework.run
                        sleep 0.1 while instance.framework.busy?

                        instance.framework.progress( sitemap: 10 )[:sitemap].should ==
                            instance.framework.sitemap_entries( 10 )
                    end
                end
            end

            describe :issue do
                context 'when set to false' do
                    it 'excludes issues' do
                        @instance_clean.framework.progress(
                            issues: false
                        ).should_not include :issues
                    end
                end
            end
            describe :as_hash do
                context 'when set to true' do
                    it 'includes issues as a hash' do
                        @instance_clean.framework.progress(
                            as_hash: true
                        )[:issues].first.is_a?( Hash ).should be_true
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
                instance = instance_spawn
                instance.options.set(
                    url: web_server_url_for( :framework_multi ),
                    scope: {
                        page_limit: 50
                    }
                )
                instance.framework.run
                sleep 0.1 while instance.framework.busy?

                sitemap = instance.framework.sitemap
                instance.framework.sitemap_entries( 10 ).should ==
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
