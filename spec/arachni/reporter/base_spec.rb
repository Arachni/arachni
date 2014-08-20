require 'spec_helper'

describe Arachni::Reporter::Base do
    before( :all ) do
        opts = Arachni::Options.instance
        opts.paths.reporters = fixtures_path + 'reporters/base_spec'

        @framework = Arachni::Framework.new
        @reporters = @framework.reporters
    end

    let(:report) { @framework.report }

    describe '#report' do
        it 'returns the provided report' do
            @reporters.run( :with_outfile, report ).report.should == report
        end
    end

    describe '#outfile' do
        it 'returns the outfile in options' do
            outfile = 'blahfile'
            @reporters.run( :with_outfile, @framework.report,
                              'outfile' => outfile
            ).outfile.should == outfile
        end

        context 'when a directory is provided as an outfile option' do
            it 'returns the path of default outfile filename under that directory' do
                @reporters.run( :with_outfile, @framework.report,
                                  'outfile' => '.'
                ).outfile.start_with?( File.expand_path( "." ) ).should be_true
            end
        end
    end

    describe '#skip_responses?' do
        context 'when the :skip_responses option is' do
            context true do
                it 'returns true' do
                    described_class.new(
                        report,
                        skip_responses: true
                    ).skip_responses?.should be_true
                end
            end

            context false do
                it 'returns false' do
                    described_class.new(
                        report,
                        skip_responses: false
                    ).skip_responses?.should be_false
                end
            end

            context 'not set' do
                it 'returns false' do
                    described_class.new( report, {} ).skip_responses?.should be_false
                end
            end
        end
    end

    describe '#format_plugin_results' do
        it 'runs the formatters of appropriate plugin' do
            store = @framework.report
            store.plugins[:foobar] = { results: 'Blah!' }

            @reporters.run( 'with_formatters', store )
            IO.read( 'with_formatters' ).should == { foobar: 'Blah!' }.to_s
            File.delete( 'with_formatters' )
        end
    end

    describe '.has_outfile?' do
        context 'when the reporter has an outfile option' do
            it 'returns true' do
                @reporters[:with_outfile].has_outfile?.should be_true
            end
        end
        context 'when the reporter does not have an outfile option' do
            it 'returns false' do
                @reporters[:without_outfile].has_outfile?.should be_false
            end
        end
    end

    describe '#has_outfile?' do
        it "delegates to #{described_class}.has_outfile?" do
            described_class.stub(:has_outfile?) { :stuff }
            described_class.new( report, {} ).has_outfile?.should == :stuff
        end
    end

end
