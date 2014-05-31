require 'spec_helper'

describe Arachni::Report::Manager do
    before( :all ) do
        Arachni::Options.paths.reports = fixtures_path + 'reports/manager_spec/'

        @reports = described_class.new
    end

    after(:all) { @reports.clear }
    after(:each) { File.delete( 'foo' ) rescue nil }
    let(:audit_store) { Factory[:audit_store] }

    describe '#run' do
        it 'runs a report by name' do
            @reports.run( 'foo', audit_store )

            File.exist?( 'foo' ).should be_true
        end

        context 'when options are given' do
            it 'passes them to the report' do
                options = { 'outfile' => 'stuff' }

                report = @reports.run( :foo, audit_store, options )

                report.options.should == options.symbolize_keys(false)
            end
        end
    end

    describe '#reset' do
        it "delegates to #{described_class}.reset" do
            described_class.stub(:reset) { :stuff }
            @reports.reset.should == :stuff
        end
    end

end
