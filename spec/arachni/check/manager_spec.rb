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
            all.size.should equal 3
            all.sort.should == checks.keys.sort
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
                checks.include?(:with_invalid_platforms).should be_false
            end
        end
    end

    describe '#schedule' do
        it 'uses each check\'s #preferred return value to sort the checks in proper running order' do
            # load them in the wrong order
            checks.load :test2
            checks.load :test3
            checks.load :test
            checks.schedule.should == [checks[:test], checks[:test2], checks[:test3]]

            checks.clear

            checks.load :test2
            checks.schedule.should == [checks[:test2]]

            checks.clear

            checks.load :test
            checks.schedule.should == [checks[:test]]

            checks.clear

            checks.load :test, :test3
            checks.schedule.should == [checks[:test], checks[:test3]]
        end
    end

    describe '#with_platforms' do
        it 'returns checks which target specific platforms' do
            checks.load_all
            checks.with_platforms.keys.should == ['test2']
        end
    end

    describe '#without_platforms' do
        it 'returns checks which do not target specific platforms' do
            checks.load_all
            checks.without_platforms.keys.sort.should == %w(test test3).sort
        end
    end

    describe '#run' do
        it 'runs all checks' do
            checks.load_all
            checks.run( page )
            issues.size.should equal 1
            issues.first.name.should == checks['test'].info[:issue][:name]
        end
    end

    describe '#run_one' do
        it 'runs a single check' do
            checks.load :test
            checks.run_one( checks.values.first, page )
            issues.size.should equal 1
            issues.first.name.should == checks['test'].info[:issue][:name]
        end

        context 'when the check was ran' do
            it 'returns true' do
                checks.load :test
                checks.run_one( checks.values.first, page ).should be_true
            end
        end

        context 'when the check was not ran' do
            it 'returns false' do
                checks.load :test

                allow(Arachni::Checks::Test).to receive(:check?).and_return(false)

                checks.run_one( checks.values.first, page ).should be_false
            end
        end
    end

end
