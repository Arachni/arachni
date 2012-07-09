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
            all = @modules.load( [ '*' ] )
            all.size.should equal 1
            all.first.should == @modules.keys.first
        end
    end

    describe '#run' do
        it 'should run all modules' do
            @modules.load( [ '*' ] )
            @modules.run( @page )
            results = @modules.results
            results.size.should equal 1
            results.first.name.should == @modules['test'].info[:issue][:name]
        end
    end

    describe '#run_one' do
        it 'should run a single module' do
            @modules.load( [ '*' ] )
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

end
