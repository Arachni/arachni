require_relative '../../spec_helper'

describe Arachni::Module::Manager do

    before( :all ) do
        opts = Arachni::Options.instance
        opts.dir['modules'] = spec_path + 'fixtures/modules/'
        @modules = Arachni::Framework.new.modules

        @page  = Arachni::Parser::Page.new
        @issue = Arachni::Issue.new( url: 'http://blah' )
    end

    before( :each ) do
        @modules.clear
        @modules.reset
    end

    describe '#load' do
        it 'should load all modules' do
            all = @modules.load_all
            all.size.should equal 3
            all.sort.should == @modules.keys.sort
        end
    end

    describe '#schedule' do
        it 'should use each module\'s #preferred return value to sort the modules in proper running order' do
            # load them in the wrong order
            @modules.load :test2
            @modules.load :test3
            @modules.load :test
            @modules.schedule.should == [@modules[:test], @modules[:test2], @modules[:test3]]

            @modules.clear

            @modules.load :test2
            @modules.schedule.should == [@modules[:test2]]

            @modules.clear

            @modules.load :test
            @modules.schedule.should == [@modules[:test]]

            @modules.clear

            @modules.load :test, :test3
            @modules.schedule.should == [@modules[:test], @modules[:test3]]
        end
    end

    describe '#run' do
        it 'should run all modules' do
            @modules.load_all
            @modules.run( @page )
            results = @modules.results
            results.size.should equal 1
            results.first.name.should == @modules['test'].info[:issue][:name]
        end
    end

    describe '#run_one' do
        it 'should run a single module' do
            @modules.load :test
            @modules.run_one( @modules.values.first, @page )
            results = @modules.results
            results.size.should equal 1
            results.first.name.should == @modules['test'].info[:issue][:name]
        end
    end

    describe '#register_results' do
        it 'should register an array of issues' do
            @modules.register_results( [ @issue ] )
            @modules.results.any?.should be true
        end

        context 'when an issue was discovered by manipulating an input' do
            it 'should not register redundant issues' do
                i = @issue.deep_clone
                i.var = 'some input'
                2.times { @modules.register_results( [ i ] ) }
                @modules.results.size.should be 1
            end
        end

        context 'when an issue was not discovered by manipulating an input' do
            it 'should register it multiple times' do
                2.times { @modules.register_results( [ @issue ] ) }
                @modules.results.size.should be 2
            end
        end
    end

    describe '#on_register_results' do
        it 'should register callbacks to be executed on new results' do
            callback_called = false
            @modules.on_register_results {
                callback_called = true
            }
            @modules.register_results( [ @issue ] )
            callback_called.should be true
        end
    end

    describe '#do_not_store' do
        it 'should not store results' do
            @modules.do_not_store
            @modules.register_results( [ @issue ] )
            @modules.results.empty?.should be true
            @modules.store
        end
    end

    describe '#results' do
        it 'should return the registered results' do
            @modules.register_results( [ @issue ] )
            @modules.results.empty?.should be false
        end

        it 'should be aliased to #issues' do
            @modules.register_results( [ @issue ] )
            @modules.results.empty?.should be false
            @modules.results.should == @modules.issues
        end
    end

    describe '.results' do
        it 'should return the registered results' do
            @modules.register_results( [ @issue ] )
            @modules.class.results.empty?.should be false
        end

        it 'should be aliased to #issues' do
            @modules.register_results( [ @issue ] )
            @modules.class.results.empty?.should be false
            @modules.class.results.should == @modules.class.issues
        end
    end

    describe '#register_results' do
        it 'should register the given issues' do
            @modules.register_results( [ @issue ] )
            @modules.results.empty?.should be false
        end
    end

    describe '.register_results' do
        it 'should register the given issues' do
            @modules.register_results( [ @issue ] )
            @modules.class.results.empty?.should be false
        end
    end
end
