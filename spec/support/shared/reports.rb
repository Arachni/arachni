shared_examples_for 'report' do
    include_examples 'component'

    before( :all ) { framework.reports.load name }
    after( :each ) { File.delete( outfile ) rescue nil }

    def self.test_with_full_report( &block )
        it 'formats a full report' do
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

    def run( auditstore, opts = {} )
        opts['outfile'] ||= outfile
        framework.reports.run_one( name, auditstore, opts )
    end

    def full_report
        Arachni::AuditStore.load( fixtures_path + '/auditstore.afr' )
    end

    def empty_report
        Arachni::AuditStore.new
    end

    def outfile
        @outfile ||= "#{Dir.tmpdir}/#{(0..10).map{ rand( 9 ).to_s }.join}"
    end

    def reports
        framework.reports
    end

end
