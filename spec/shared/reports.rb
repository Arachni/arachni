shared_examples_for "report" do
    include_examples 'component'

    before( :all ) { framework.reports.load name }
    #before( :each ) { framework.reports.reset }

    after( :each ) { File.delete( outfile ) rescue nil }

    def self.test_with_full_report( &block )
        it 'should be able to handle a full report' do
            run( full_report )
            instance_eval( &block ) if block_given?
        end
    end

    def self.test_with_empty_report( &block )
        it 'should be able to handle an empty report' do
            run( empty_report )
            instance_eval( &block ) if block_given?
        end
    end

    def run( auditstore, opts = {} )
        opts['outfile'] ||= outfile

        #report_name = File.basename( caller.first.split( ':' ).first, '_spec.rb' )

        framework.reports.run_one( name, auditstore, opts )
    end

    def full_report
        Arachni::AuditStore.load( spec_path + 'fixtures/auditstore.afr' )
    end

    def empty_report
        Arachni::AuditStore.new
    end

    def outfile
        @outfile ||= (0..10).map{ rand( 9 ).to_s }.join
    end

    def reports
        framework.reports
    end

end
