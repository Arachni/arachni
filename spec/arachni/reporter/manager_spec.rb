require 'spec_helper'

describe Arachni::Reporter::Manager do
    before( :all ) do
        Arachni::Options.paths.reporters = fixtures_path + 'reporters/manager_spec/'

        @reporters = described_class.new
    end

    after(:all) { @reporters.clear }
    after(:each) { File.delete( 'foo' ) rescue nil }
    let(:report) { Factory[:report] }

    describe '#run' do
        it 'runs a reporter by name' do
            @reporters.run( 'foo', report )

            File.exist?( 'foo' ).should be_true
        end

        context 'when options are given' do
            it 'passes them to the reporter' do
                options = { 'outfile' => 'stuff' }
                reporter = @reporters.run( :foo, report, options )

                reporter.options.should == options.symbolize_keys(false)
            end
        end
    end

    describe '#reset' do
        it "delegates to #{described_class}.reset" do
            described_class.stub(:reset) { :stuff }
            @reporters.reset.should == :stuff
        end
    end

end
