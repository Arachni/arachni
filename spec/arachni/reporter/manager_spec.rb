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

            expect(File.exist?( 'foo' )).to be_truthy
        end

        context 'when options are given' do
            it 'passes them to the reporter' do
                options = { 'outfile' => 'stuff' }
                reporter = @reporters.run( :foo, report, options )

                expect(reporter.options).to eq(options.my_symbolize_keys(false))
            end
        end

        context 'when the raise argument is'do
            context 'not given' do
                context 'and the report raises an exception' do
                    it 'does not raise it' do
                        expect { @reporters.run( :error, report ) }.to_not raise_error
                    end
                end
            end

            context 'false' do
                context 'and the report raises an exception' do
                    it 'does not raise it' do
                        expect { @reporters.run( :error, report, {}, false ) }.to_not raise_error
                    end
                end
            end

            context 'true' do
                context 'and the report raises an exception' do
                    it 'does not raise it' do
                        expect { @reporters.run( :error, report, {}, true ) }.to raise_error
                    end
                end
            end
        end
    end

    describe '#reset' do
        it "delegates to #{described_class}.reset" do
            allow(described_class).to receive(:reset) { :stuff }
            expect(@reporters.reset).to eq(:stuff)
        end
    end

end
