# require 'spec_helper'
#
# describe 'Arachni::RPC::Server::Framework' do
#     before( :all ) do
#         @opts = Arachni::Options.instance
#         @opts.paths.checks = fixtures_path + '/signature_check/'
#         @opts.audit.elements :links, :forms, :cookies
#
#         @instance  = instance_light_grid_spawn
#         @framework = @instance.framework
#         @checks    = @instance.checks
#         @plugins   = @instance.plugins
#
#         @instance_clean  = instance_light_grid_spawn
#         @framework_clean = @instance_clean.framework
#
#         @statistics_keys = [:http, :found_pages, :audited_pages, :runtime]
#     end
#
#     describe '#errors' do
#         context 'when no argument has been provided' do
#             it 'returns all logged errors' do
#                 test = 'Test'
#                 @framework.error_test test
#                 expect(@framework.errors.last).to end_with test
#             end
#         end
#         context 'when a start line-range has been provided' do
#             it 'returns all logged errors after that line' do
#                 initial_errors = @framework.errors
#                 errors = @framework.errors( 10 )
#
#                 expect(initial_errors[10..-1]).to eq(errors)
#             end
#         end
#     end
#
#     describe '#busy?' do
#         context 'when the scan is not running' do
#             it 'returns false' do
#                 expect(@framework_clean.busy?).to be_falsey
#             end
#         end
#         context 'when the scan is running' do
#             it 'returns true' do
#                 @instance.options.url = web_server_url_for( :auditor )
#                 @checks.load( 'taint' )
#                 expect(@framework.run).to be_truthy
#                 expect(@framework.busy?).to be_truthy
#             end
#         end
#     end
#     describe '#version' do
#         it 'returns the system version' do
#             expect(@framework_clean.version).to eq(Arachni::VERSION)
#         end
#     end
#     describe '#master?' do
#         it 'returns false' do
#             expect(@framework_clean.master?).to be_truthy
#         end
#     end
#     describe '#slave?' do
#         it 'returns false' do
#             expect(@framework_clean.slave?).to be_falsey
#         end
#     end
#     describe '#solo?' do
#         it 'returns true' do
#             expect(@framework_clean.solo?).to be_falsey
#         end
#     end
#     describe '#set_as_master' do
#         it 'sets the instance as the master' do
#             instance = instance_spawn
#             expect(instance.framework.master?).to be_falsey
#             instance.framework.set_as_master
#             expect(instance.framework.master?).to be_truthy
#
#             instance_kill instance.url
#         end
#     end
#     describe '#enslave' do
#         it 'enslaves another instance and set itself as its master' do
#             master = instance_spawn
#             slave  = instance_spawn
#
#             expect(master.framework.master?).to be_falsey
#             master.framework.enslave(
#                 'url'   => slave.url,
#                 'token' => instance_token_for( slave )
#             )
#             expect(master.framework.master?).to be_truthy
#
#             instance_kill master.url
#         end
#     end
#     describe '#run' do
#         it 'performs a scan' do
#             instance = @instance_clean
#             instance.options.url = web_server_url_for( :framework_multi )
#             instance.checks.load( 'taint' )
#             expect(instance.framework.run).to be_truthy
#             sleep( 1 ) while instance.framework.busy?
#             expect(instance.framework.issues.size).to eq(500)
#         end
#
#         it 'handles pages with JavaScript code' do
#             instance = instance_light_grid_spawn
#             instance.options.url = web_server_url_for( :auditor ) + '/with_javascript'
#             instance.checks.load :signature
#
#             expect(instance.framework.run).to be_truthy
#             sleep 0.1 while instance.framework.busy?
#
#             expect(instance.framework.issues.
#                 map { |i| i.vector.affected_input_name }.uniq).to be
#                     %w(link_input form_input cookie_input)
#
#             # dispatcher_kill_by_instance instance
#         end
#
#         it 'handles AJAX' do
#             instance = instance_light_grid_spawn
#             instance.options.url = web_server_url_for( :auditor ) + '/with_ajax'
#             instance.checks.load :signature
#
#             expect(instance.framework.run).to be_truthy
#             sleep 0.1 while instance.framework.busy?
#
#             expect(instance.framework.issues.
#                 map { |i| i.vector.affected_input_name }.uniq).to be
#                     %w(link_input form_input cookie_taint).sort
#
#             # dispatcher_kill_by_instance instance
#         end
#     end
#     describe '#report' do
#         it 'returns an report object' do
#             report = @instance_clean.framework.report
#             expect(report.is_a?( Arachni::Report )).to be_truthy
#             expect(report.issues).to be_any
#         end
#     end
#     describe '#statistics' do
#         it 'returns a hash containing general runtime statistics' do
#             statistics = @instance_clean.framework.statistics
#
#             keys = @statistics_keys | [:current_page]
#
#             expect(statistics.keys.sort).to eq(keys.sort)
#             keys.each { |k| expect(statistics[k]).to be_truthy }
#         end
#     end
#     describe '#clean_up' do
#         it 'sets the framework state to finished, waits for plugins to finish and merges their results' do
#             @instance = instance = instance_light_grid_spawn
#             instance.options.url = web_server_url_for( :framework_multi )
#             instance.checks.load( 'taint' )
#             instance.plugins.load( { 'wait' => {}, 'distributable' => {} } )
#             expect(instance.framework.run).to be_truthy
#             expect(instance.framework.report.plugins).to be_empty
#
#             # Wait till the slaves join the scan.
#             sleep 0.1 while instance.framework.progress[:instances].size != 3
#
#             expect(instance.framework.clean_up).to be_truthy
#
#             instance_count = instance.framework.progress[:instances].size
#             report     = instance.framework.report
#
#             results = report.plugins
#             expect(results).to be_any
#             expect(results[:wait]).to be_any
#             expect(results[:wait][:results]).to eq({ 'stuff' => true })
#             expect(results[:distributable][:results]).to eq({ 'stuff' => instance_count })
#
#             # dispatcher_kill_by_instance instance
#         end
#     end
#     describe '#progress' do
#         before { @progress_keys = %W(statistics status busy issues instances).map(&:to_sym).sort }
#
#         context 'when called without options' do
#             it 'returns all progress data' do
#                 instance = @instance_clean
#
#                 data = instance.framework.progress
#
#                 expect(data.keys.sort).to eq((@progress_keys | [:master]).flatten.sort)
#
#                 expect(data[:statistics].keys.sort).to eq(
#                     (@statistics_keys | [:current_pages]).flatten.sort
#                 )
#
#                 expect(data[:status]).to be_kind_of Symbol
#                 expect(data[:master]).to eq(instance.url)
#                 expect(data[:busy]).not_to be_nil
#                 expect(data[:issues]).to be_any
#                 expect(data[:instances].size).to eq(3)
#
#                 expect(data).not_to include :errors
#
#                 keys = (@statistics_keys | [:current_page]).flatten.sort
#
#                 data[:instances].each do |i|
#                     expect(i[:statistics].keys.sort).to eq(keys)
#                     expect(i.keys.sort).to eq([:url, :statistics, :status, :busy, :messages].sort)
#                 end
#
#                 data.delete :issues
#             end
#         end
#
#         context 'when called with option' do
#             describe ':errors' do
#                 context 'when set to true' do
#                     it 'includes all error messages' do
#                         instance = instance_light_grid_spawn
#                         expect(instance.framework.progress( errors: true )[:errors]).to be_empty
#
#                         test = 'Test'
#                         instance.framework.error_test test
#
#                         expect(instance.framework.progress( errors: true )[:errors].last).to end_with test
#
#                         # dispatcher_kill_by_instance instance
#                     end
#                 end
#                 context 'when set to an Integer' do
#                     it 'returns all logged errors after that line per Instance' do
#                         instance = instance_light_grid_spawn
#
#                         100.times { instance.framework.error_test 'test' }
#
#                         expect(instance.framework.progress( errors: true )[:errors].size -
#                             instance.framework.progress( errors: 10 )[:errors].size).to eq(10)
#
#                         # dispatcher_kill_by_instance instance
#                     end
#                 end
#             end
#
#             describe ':sitemap' do
#                 context 'when set to true' do
#                     it 'returns entire sitemap' do
#                         expect(@instance_clean.framework.
#                             progress( sitemap: true )[:sitemap]).to eq(
#                                 @instance_clean.framework.sitemap
#                         )
#                     end
#                 end
#
#                 context 'when an index has been provided' do
#                     it 'returns all entries after that line' do
#                         expect(@instance_clean.framework.progress( sitemap: 10 )[:sitemap]).to eq(
#                             @instance_clean.framework.sitemap_entries( 10 )
#                         )
#                     end
#                 end
#             end
#
#             describe ':statistics' do
#                 context 'when set to false' do
#                     it 'excludes statistics' do
#                         expect(@instance_clean.framework.progress(
#                             statistics: false
#                         )).not_to include :statistics
#                     end
#                 end
#             end
#             describe ':issues' do
#                 context 'when set to false' do
#                     it 'excludes issues' do
#                         expect(@instance_clean.framework.progress(
#                             issues: false
#                         )).not_to include :issues
#                     end
#                 end
#             end
#             describe ':slaves' do
#                 context 'when set to false' do
#                     it 'excludes slave data' do
#                         expect(@instance_clean.framework.progress(
#                             slaves: false
#                         )).not_to include :instances
#                     end
#                 end
#             end
#             describe ':as_hash' do
#                 context 'when set to true' do
#                     it 'includes issues as a hash' do
#                         expect(@instance_clean.framework.
#                             progress( as_hash: true )[:issues].
#                                 first.is_a?( Hash )).to be_truthy
#                     end
#                 end
#             end
#         end
#     end
#
#     describe '#sitemap_entries' do
#         context 'when no argument has been provided' do
#             it 'returns entire sitemap' do
#                 expect(@instance_clean.framework.sitemap_entries).to eq(
#                     @instance_clean.framework.sitemap
#                 )
#             end
#         end
#
#         context 'when an index has been provided' do
#             it 'returns all entries after that line' do
#                 sitemap = @instance_clean.framework.sitemap
#                 expect(@instance_clean.framework.sitemap_entries( 10 )).to eq(
#                     Hash[sitemap.to_a[10..-1]]
#                 )
#             end
#         end
#     end
#
#     describe '#issues' do
#         it 'returns an array of issues' do
#             issues = @instance_clean.framework.issues
#             expect(issues).to be_any
#
#             issue = issues.first
#             expect(issue.is_a?( Arachni::Issue )).to be_truthy
#         end
#     end
#
#     describe '#issues_as_hash' do
#         it 'returns an array of issues as hash' do
#             issues = @instance_clean.framework.issues_as_hash
#             expect(issues).to be_any
#
#             issue = issues.first
#             expect(issue.is_a?( Hash )).to be_truthy
#         end
#     end
# end
