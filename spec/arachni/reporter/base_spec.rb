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
            expect(@reporters.run( :with_outfile, report ).report).to eq(report)
        end
    end

    describe '#outfile' do
        it 'returns the outfile in options' do
            outfile = 'blahfile'
            expect(@reporters.run( :with_outfile, @framework.report,
                              'outfile' => outfile
            ).outfile).to eq(outfile)
        end

        context 'when a directory is provided as an outfile option' do
            it 'returns the path of default outfile filename under that directory' do
                expect(@reporters.run( :with_outfile, @framework.report,
                                  'outfile' => '.'
                ).outfile.start_with?( File.expand_path( "." ) )).to be_truthy
            end
        end
    end

    describe '#skip_responses?' do
        context 'when the :skip_responses option is' do
            context 'true' do
                it 'returns true' do
                    expect(described_class.new(
                        report,
                        skip_responses: true
                    ).skip_responses?).to be_truthy
                end
            end

            context 'false' do
                it 'returns false' do
                    expect(described_class.new(
                        report,
                        skip_responses: false
                    ).skip_responses?).to be_falsey
                end
            end

            context 'not set' do
                it 'returns false' do
                    expect(described_class.new( report, {} ).skip_responses?).to be_falsey
                end
            end
        end
    end

    describe '#format_plugin_results' do
        it 'runs the formatters of appropriate plugin' do
            store = @framework.report
            store.plugins[:foobar] = { results: 'Blah!' }

            @reporters.run( 'with_formatters', store )
            expect(IO.read( 'with_formatters' )).to eq({ foobar: 'Blah!' }.to_s)
            File.delete( 'with_formatters' )
        end
    end

    describe '.has_outfile?' do
        context 'when the reporter has an outfile option' do
            it 'returns true' do
                expect(@reporters[:with_outfile].has_outfile?).to be_truthy
            end
        end
        context 'when the reporter does not have an outfile option' do
            it 'returns false' do
                expect(@reporters[:without_outfile].has_outfile?).to be_falsey
            end
        end
    end

    describe '#has_outfile?' do
        it "delegates to #{described_class}.has_outfile?" do
            allow(described_class).to receive(:has_outfile?) { :stuff }
            expect(described_class.new( report, {} ).has_outfile?).to eq(:stuff)
        end
    end

end
