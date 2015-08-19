require 'spec_helper'

describe Arachni::Check::Manager do

    before( :all ) do
        @framework = Arachni::Framework.new
        @checks    = @framework.checks
    end

    after(:each) do
        @checks.clear
        @framework.reset
    end

    let(:page) { Arachni::Page.from_url( url ) }
    let(:checks) { @checks }
    let(:url) { Arachni::Utilities.normalize_url( web_server_url_for( :auditor ) ) }
    let(:issue) { Factory[:issue] }

    describe '#load' do
        it 'loads all checks' do
            all = checks.load_all
            expect(all.size).to equal 3
            expect(all.sort).to eq(checks.keys.sort)
        end
    end

    describe '#[]' do
        context 'when the check contains invalid platforms' do
            it "raises #{described_class::Error::InvalidPlatforms}" do
                checks.clear
                checks.reset

                Arachni::Options.paths.checks = fixtures_path + 'check_with_invalid_platforms/'
                checks = Arachni::Framework.new.checks

                expect { checks[:with_invalid_platforms] }.to raise_error described_class::Error::InvalidPlatforms
                expect(checks.include?(:with_invalid_platforms)).to be_falsey
            end
        end
    end

    describe '#schedule' do
        it 'uses each check\'s #preferred return value to sort the checks in proper running order' do
            # load them in the wrong order
            checks.load :test2
            checks.load :test3
            checks.load :test
            expect(checks.schedule).to eq([checks[:test], checks[:test2], checks[:test3]])

            checks.clear

            checks.load :test2
            expect(checks.schedule).to eq([checks[:test2]])

            checks.clear

            checks.load :test
            expect(checks.schedule).to eq([checks[:test]])

            checks.clear

            checks.load :test, :test3
            expect(checks.schedule).to eq([checks[:test], checks[:test3]])
        end
    end

    describe '#with_platforms' do
        it 'returns checks which target specific platforms' do
            checks.load_all
            expect(checks.with_platforms.keys).to eq(['test2'])
        end
    end

    describe '#without_platforms' do
        it 'returns checks which do not target specific platforms' do
            checks.load_all
            expect(checks.without_platforms.keys.sort).to eq(%w(test test3).sort)
        end
    end

    describe '#run' do
        it 'runs all checks' do
            checks.load_all
            checks.run( page )
            expect(issues.size).to equal 1
            expect(issues.first.name).to eq(checks['test'].info[:issue][:name])
        end
    end

    describe '#run_one' do
        it 'runs a single check' do
            checks.load :test
            checks.run_one( checks.values.first, page )
            expect(issues.size).to equal 1
            expect(issues.first.name).to eq(checks['test'].info[:issue][:name])
        end

        context 'when the check was ran' do
            it 'returns true' do
                checks.load :test
                expect(checks.run_one( checks.values.first, page )).to be_truthy
            end
        end

        context 'when the check was not ran' do
            it 'returns false' do
                checks.load :test

                allow(Arachni::Checks::Test).to receive(:check?).and_return(false)

                expect(checks.run_one( checks.values.first, page )).to be_falsey
            end
        end
    end

end
