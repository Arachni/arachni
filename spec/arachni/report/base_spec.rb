require_relative '../../spec_helper'

describe Arachni::Report::Base do
    before( :all ) do
        opts = Arachni::Options.instance
        opts.dir['reports'] = spec_path + 'fixtures/reports/base_spec'

        @framework = Arachni::Framework.new( Arachni::Options.instance )
        @reports   = @framework.reports
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

end
