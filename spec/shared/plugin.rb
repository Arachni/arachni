shared_examples_for "plugin" do
    include_examples 'component'

    before( :all ) do
        framework.plugins.load name
    end

    def results
    end

    def self.easy_test( &block )
        it "should log the expected results" do
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
