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
            framework.plugins.results[name].should eq( (results == :nil) ? nil : results )

            instance_eval &block if block_given?
        end
    end

end
