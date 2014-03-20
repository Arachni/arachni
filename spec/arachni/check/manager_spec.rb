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
            results = checks.results
            results.size.should equal 1
            results.first.name.should == checks['test'].info[:issue][:name]
        end
    end

    describe '#run_one' do
        it 'runs a single check' do
            checks.load :test
            checks.run_one( checks.values.first, page )
            results = checks.results
            results.size.should equal 1
            results.first.name.should == checks['test'].info[:issue][:name]
        end
    end

    describe '#register_results' do
        it 'registers an array of issues' do
            checks.register_results( [ issue ] )
            checks.results.any?.should be true
        end

        context 'when an issue was discovered by manipulating an input' do
            it 'does not register redundant issues' do
                i = issue.deep_clone
                i.vector.affected_input_name = 'some input'
                2.times { checks.register_results( [ i ] ) }
                checks.results.size.should be 1
            end
        end

        context 'when an issue was not discovered by manipulating an input' do
            it 'registers it multiple times' do
                2.times { checks.register_results( [ issue ] ) }
                checks.results.size.should be 2
            end
        end
    end

    describe '#on_register_results' do
        it 'registers callbacks to be executed on new results' do
            callback_called = false
            checks.on_register_results { callback_called = true }
            checks.register_results( [ issue ] )
            callback_called.should be true
        end
    end

    describe '#do_not_store' do
        it 'does not store results' do
            checks.do_not_store
            checks.register_results( [ issue ] )
            checks.results.empty?.should be true
            checks.store
        end
    end

    describe '#results' do
        it 'returns the registered results' do
            checks.register_results( [ issue ] )
            checks.results.empty?.should be false
        end

        it 'aliased to #issues' do
            checks.register_results( [ issue ] )
            checks.results.empty?.should be false
            checks.results.should == checks.issues
        end
    end

    describe '.results' do
        it 'returns the registered results' do
            checks.register_results( [ issue ] )
            checks.class.results.empty?.should be false
        end

        it 'aliased to #issues' do
            checks.register_results( [ issue ] )
            checks.class.results.empty?.should be false
            checks.class.results.should == checks.class.issues
        end
    end

    describe '#register_results' do
        it 'registers the given issues' do
            checks.register_results( [ issue ] )
            checks.results.empty?.should be false
        end
    end

    describe '.register_results' do
        it 'registers the given issues' do
            checks.register_results( [ issue ] )
            checks.class.results.empty?.should be false
        end
    end
end
