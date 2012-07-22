require_relative '../../spec_helper'

describe Arachni::Report::Base do
    before( :all ) do
        opts = Arachni::Options.instance
        opts.dir['reports'] = spec_path + 'fixtures/reports/base_spec'

        @framework = Arachni::Framework.new( Arachni::Options.instance )
        @reports   = @framework.reports
    end

    describe '#auditstore' do
        it 'should return the provided auditstore' do
            auditstore = @framework.auditstore
            @reports.run_one( :with_outfile, auditstore ).auditstore.
                should == auditstore
        end
    end

    describe '#outfile' do
        it 'should return the outfile in options' do
            outfile = 'blahfile'
            @reports.run_one( :with_outfile, @framework.auditstore,
                              'outfile' => outfile
            ).outfile.should == outfile
        end
    end

    describe '#format_plugin_results' do
        it 'should run the formatters of appropriate plugin' do
            store = @framework.auditstore
            store.plugins["foobar"] = { :results => 'Blah!' }

            @reports.run_one( 'with_formatters', store )
            IO.read( 'with_formatters' ).should == { 'foobar' => 'Blah!' }.to_s
            File.delete( 'with_formatters' )
        end
    end

    describe '.has_outfile?' do
        context 'when the report has an outfile option' do
            it 'should return true' do
                @reports[:with_outfile].has_outfile?.should be_true
            end
        end
        context 'when the report does not have an outfile option' do
            it 'should return false' do
                @reports[:without_outfile].has_outfile?.should be_false
            end
        end
    end

end
