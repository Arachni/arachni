shared_examples_for "plugin" do
    include_examples 'component'

    before( :all ) do
        FileUtils.cp "#{fixtures_path}modules/test2.rb", options.dir['modules']
        framework.modules.load :test2

        framework.plugins.load name
    end
    before( :each ) do
        framework.reset_spider
        framework.plugins.reset
    end

    after( :all ) { FileUtils.rm "#{options.dir['modules']}test2.rb" }

    def results
    end

    def self.easy_test( &block )
        it "logs the expected results" do
            raise 'No results provided via #results, use \':nil\' for \'nil\' results.' if !results

            run
            actual_results.should be_eql( expected_results )

            instance_eval &block if block_given?
        end
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
