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
                expect(@instance.framework.errors.last).to end_with test
            end
        end
        context 'when a start line-range has been provided' do
            it 'returns all logged errors after that line' do
                initial_errors = @instance.framework.errors
                errors = @instance.framework.errors( 10 )

                expect(initial_errors[10..-1]).to eq(errors)
            end
        end
    end

    describe '#busy?' do
        context 'when the scan is not running' do
            it 'returns false' do
                expect(@framework_clean.busy?).to be_falsey
            end
        end
        context 'when the scan is running' do
            it 'returns true' do
                @instance.options.url = web_server_url_for( :auditor ) + '/sleep'
                @checks.load( 'test' )
                expect(@framework.run).to be_truthy
                expect(@framework.busy?).to be_truthy
            end
        end
    end
    describe '#version' do
        it 'returns the system version' do
            expect(@framework_clean.version).to eq(Arachni::VERSION)
        end
    end
    describe '#master?' do
        it 'returns false' do
            expect(@framework_clean.master?).to be_falsey
        end
    end
    describe '#slave?' do
        it 'returns false' do
            expect(@framework_clean.slave?).to be_falsey
        end
    end
    describe '#solo?' do
        it 'returns true' do
            expect(@framework_clean.solo?).to be_truthy
        end
    end
    describe '#list_plugins' do
        it 'lists all available plugins' do
            plugins = @framework_clean.list_plugins
            expect(plugins.size).to eq(7)
            plugin = plugins.select { |i| i[:name] =~ /default/i }.first
            expect(plugin[:name]).to eq('Default')
            expect(plugin[:description]).to eq('Some description')
            expect(plugin[:author].size).to eq(1)
            expect(plugin[:author].first).to eq('Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>')
            expect(plugin[:version]).to eq('0.1')
            expect(plugin[:shortname]).to eq('default')
            expect(plugin[:options].size).to eq(1)

            opt = plugin[:options].first
            expect(opt[:name]).to eq(:int_opt)
            expect(opt[:required]).to eq(false)
            expect(opt[:description]).to eq('An integer.')
            expect(opt[:default]).to eq(4)
            expect(opt[:type]).to eq(:integer)
        end
    end
    describe '#list_reporters' do
        it 'lists all available reporters' do
            reporters = @framework_clean.list_reporters
            expect(reporters).to be_any
            report_with_opts = reporters.select{ |r| r[:options].any? }.first
            expect(report_with_opts[:options].first).to be_kind_of( Hash )
        end
    end

    describe '#list_checks' do
        it 'lists all available checks' do
            expect(@framework_clean.list_checks).to be_any
        end
    end

    describe '#list_platforms' do
        it 'lists all available platforms' do
            expect(@framework_clean.list_platforms).to eq(Arachni::Framework.new.list_platforms)
        end
    end

    describe '#run' do
        it 'performs a scan' do
            instance = @instance_clean
            instance.options.url = web_server_url_for( :framework )
            instance.checks.load( 'test' )
            instance.framework.run
            sleep( 1 ) while instance.framework.busy?
            expect(instance.framework.issues).to be_any
        end

        it 'handles pages with JavaScript code' do
            @opts.paths.checks = fixtures_path + '/signature_check/'

            instance = instance_spawn
            instance.options.url = web_server_url_for( :auditor ) + '/with_javascript'
            instance.options.set audit: { elements: [:links, :forms, :cookies] }
            instance.checks.load :signature

            instance.framework.run
            sleep 0.1 while instance.framework.busy?

            expect(instance.framework.issues.
                map { |i| i.vector.affected_input_name }.uniq).to be
                %w(link_input form_input cookie_input).sort
        end

        it 'handles AJAX' do
            @opts.paths.checks = fixtures_path + '/signature_check/'

            instance = instance_spawn
            instance.options.url = web_server_url_for( :auditor ) + '/with_ajax'
            instance.options.set audit: { elements: [:links, :forms, :cookies] }
            instance.checks.load :signature

            instance.framework.run
            sleep 0.1 while instance.framework.busy?

            expect(instance.framework.issues.
                map { |i| i.vector.affected_input_name }.uniq).to be
                %w(link_input form_input cookie_taint).sort
        end

    end
    describe '#report' do
        it 'returns an report object' do
            report = @instance_clean.framework.report
            expect(report.is_a?( Arachni::Report )).to be_truthy
            expect(report.issues).to be_any
        end
    end
    describe '#statistics' do
        it 'returns a hash containing general runtime statistics' do
            instance = @instance_clean
            instance.options.url = web_server_url_for( :framework )
            instance.checks.load( 'test' )
            expect(instance.framework.run).to be_truthy

            expect(instance.framework.statistics).to be_kind_of Hash
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
                expect(@instance.framework.status).to eq(:ready)
            end
        end
        context 'after #run has been called' do
            it 'returns :scanning' do
                expect(@instance.framework.run).to be_truthy
                sleep 2
                expect(@instance.framework.status).to eq(:scanning)
            end
        end
        context 'once the scan had completed' do
            it 'returns :done' do
                instance = instance_spawn
                instance.options.url = web_server_url_for( :framework )
                instance.checks.load( 'test' )
                instance.framework.run
                sleep 1 while instance.framework.busy?
                expect(instance.framework.status).to eq(:done)
            end
        end
    end
    describe '#clean_up' do
        it 'sets the framework state to finished and wait for plugins to finish' do
            instance = instance_spawn
            instance.options.url = web_server_url_for( :framework_multi )
            instance.checks.load( 'test' )
            instance.plugins.load( { 'wait' => {} } )
            expect(instance.framework.run).to be_truthy
            expect(instance.framework.busy?).to be_truthy
            expect(instance.framework.report.plugins).to be_empty
            expect(instance.framework.clean_up).to be_truthy
            results = instance.framework.report.plugins
            expect(results).to be_any
            expect(results[:wait]).to be_any
            expect(results[:wait][:results]).to eq({ 'stuff' => true })
        end
    end
    describe '#progress' do
        before { @progress_keys = %W(seed statistics status busy messages issues).sort.map(&:to_sym) }

        context 'when called without options' do
            it 'returns all progress data' do
                instance = @instance_clean

                data = instance.framework.progress
                expect(data.keys.sort).to eq(@progress_keys)

                expect(data[:statistics].keys).to eq(instance.framework.statistics.keys)
                expect(data[:messages]).to be_empty
                expect(data[:status]).to be_truthy
                expect(data[:busy].nil?).to be_falsey
                expect(data[:issues]).to be_any
                expect(data[:seed]).not_to be_empty
                expect(data).not_to include :errors
            end
        end

        context 'when called with option' do
            describe ':errors' do
                context 'when set to true' do
                    it 'includes all error messages' do
                        expect(@instance_clean.framework.
                            progress( errors: true )[:errors]).to be_empty

                        test = 'Test'
                        @instance_clean.framework.error_test test

                        expect(@instance_clean.framework.
                            progress( errors: true )[:errors].last).
                                to end_with test
                    end
                end
                context 'when set to an Integer' do
                    it 'returns all logged errors after that line' do
                        @instance_clean.framework.error_test 'test'

                        initial_errors = @instance_clean.framework.
                            progress( errors: true )[:errors]

                        errors = @instance_clean.framework.
                            progress( errors: 10 )[:errors]

                        expect(errors).to eq(initial_errors[10..-1])
                    end
                end
            end

            describe ':sitemap' do
                context 'when set to true' do
                    it 'returns entire sitemap' do
                        expect(@instance_clean.framework.
                            progress( sitemap: true )[:sitemap]).to eq(
                            @instance_clean.framework.sitemap
                        )
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

                        expect(instance.framework.progress( sitemap: 10 )[:sitemap]).to eq(
                            instance.framework.sitemap_entries( 10 )
                        )
                    end
                end
            end

            describe ':issue' do
                context 'when set to false' do
                    it 'excludes issues' do
                        expect(@instance_clean.framework.progress(
                            issues: false
                        )).not_to include :issues
                    end
                end
            end
            describe ':as_hash' do
                context 'when set to true' do
                    it 'includes issues as a hash' do
                        expect(@instance_clean.framework.progress(
                            as_hash: true
                        )[:issues].first.is_a?( Hash )).to be_truthy
                    end
                end
            end
        end
    end

    describe '#sitemap_entries' do
        context 'when no argument has been provided' do
            it 'returns entire sitemap' do
                expect(@instance_clean.framework.sitemap_entries).to eq(
                    @instance_clean.framework.sitemap
                )
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
                expect(instance.framework.sitemap_entries( 10 )).to eq(
                    Hash[sitemap.to_a[10..-1]]
                )
            end
        end
    end

    describe '#self_url' do
        it 'returns the RPC URL' do
            expect(@instance_clean.framework.self_url).to eq(@instance_clean.url)
        end
    end

    describe '#token' do
        it 'returns the RPC token' do
            expect(@instance_clean.framework.token).to eq(instance_token_for( @instance_clean ))
        end
    end

    describe '#report_as' do
        context 'when passed a valid reporter name' do
            it 'returns the report as a string' do
                json = @instance_clean.framework.report_as( :json )
                expect(JSON.load( json )['issues'].size).to eq(
                    @instance_clean.framework.report.issues.size
                )
            end

            context 'which does not support the \'outfile\' option' do
                it 'raises an exception' do
                    expect { @instance_clean.framework.report_as( :stdout ) }.to raise_error
                end
            end
        end

        context 'when passed an invalid reporter name' do
            it 'raises an exception' do
                expect { @instance_clean.framework.report_as( :blah ) }.to raise_error
            end
        end
    end

    describe '#issues' do
        it 'returns an array of issues' do
            issues = @instance_clean.framework.issues
            expect(issues).to be_any

            issue = issues.first
            expect(issue.is_a?( Arachni::Issue )).to be_truthy
        end
    end

    describe '#issues_as_hash' do
        it 'returns an array of issues as hash' do
            issues = @instance_clean.framework.issues_as_hash
            expect(issues).to be_any

            issue = issues.first
            expect(issue.is_a?( Hash )).to be_truthy
        end
    end
end
