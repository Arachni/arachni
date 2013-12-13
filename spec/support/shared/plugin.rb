shared_examples_for "plugin" do
    include_examples 'component'

    before( :all ) do
        FileUtils.cp "#{fixtures_path}checks/test2.rb", options.dir['checks']
        framework.checks.load :test2

        framework.plugins.load name
    end
    before( :each ) do
        framework.reset_filters
        framework.reset_spider
        framework.plugins.reset
        framework.reports.clear
    end

    after( :all ) { FileUtils.rm "#{options.dir['checks']}test2.rb" }

    def results
    end

    def self.easy_test( &block )
        it 'logs the expected results' do
            raise 'No results provided via #results, use \':nil\' for \'nil\' results.' if !results

            run
            actual_results.should be_eql( expected_results )

            instance_eval &block if block_given?
        end
    end

    def run
        framework.run

        # Make sure plugin formatters work as well.
        framework.reports.load_all
        framework.reports.each do |name, klass|
            framework.reports.run_one name, framework.auditstore, 'outfile' => outfile
            File.delete( outfile ) rescue nil
        end
    end

    def outfile
        @outfile ||= "#{Dir.tmpdir}/#{(0..10).map{ rand( 9 ).to_s }.join}"
    end

    def actual_results
        results_for( name )
    end

    def results_for( name )
        (framework.plugins.results[name] || {})[:results]
    end

    def expected_results
        return nil if results == :nil

        (results.is_a?( String ) && results.include?( '__URL__' )) ?
            yaml_load( results ) : results
    end

    def current_plugin
        framework.plugins[name]
    end

end
