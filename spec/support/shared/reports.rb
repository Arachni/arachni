shared_examples_for 'reporter' do
    include_examples 'component'

    before( :all ) { framework.reports.load name }
    after( :each ) { File.delete( outfile ) rescue nil }

    def self.test_with_full_report( &block )
        it 'formats a full reporter' do
            run( full_report )
            instance_eval( &block ) if block_given?
        end
    end

    def self.test_with_empty_report( &block )
        it 'can handle an empty report' do
            run( empty_report )
            instance_eval( &block ) if block_given?
        end
    end

    def run( report, opts = {} )
        opts['outfile'] ||= outfile
        reporters.run_one( name, report, opts )
    end

    def full_report
        Arachni::Report.load( fixtures_path + '/report.afr' )
    end

    def empty_report
        Arachni::Report.new
    end

    def outfile
        @outfile ||= "#{Dir.tmpdir}/#{(0..10).map{ rand( 9 ).to_s }.join}"
    end

    def reporters
        framework.reporters
    end

end
