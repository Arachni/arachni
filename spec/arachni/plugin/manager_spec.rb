require 'spec_helper'

describe Arachni::Plugin::Manager do
    before( :all ) do
        @plugins = Arachni::Framework.new.plugins
    end

    after( :all ) { @plugins.clear }

    describe '#load_default' do
        it 'loads default plugins' do
            @plugins.should be_empty
            @plugins.load_default
            @plugins.include?( 'default' ).should be_true
            @plugins.clear
        end
        it 'aliased to #load_defaults' do
            @plugins.should be_empty
            @plugins.load_defaults
            @plugins.include?( 'default' ).should be_true
        end
    end

    describe '#default' do
        it 'returns the default plugins' do
            @plugins.default.include?( 'default' ).should be_true
        end
        it 'aliased to #defaults' do
            @plugins.defaults.include?( 'default' ).should be_true
        end
    end

    describe '#run' do
        context 'when gem dependencies are met' do
            it 'runs loaded plugins' do
                @plugins.run
                @plugins.block
                @plugins.results[:default][:results].should be_true
            end
        end
        context 'when gem dependencies are not met' do
            it "raises #{Arachni::Plugin::Error::UnsatisfiedDependency}" do
                trigger = proc do
                    begin
                        @plugins.load :bad
                        @plugins.run
                        @plugins.block
                    ensure
                        @plugins.clear
                    end
                end

                expect { trigger.call }.to raise_error Arachni::Error
                expect { trigger.call }.to raise_error Arachni::Plugin::Error
                expect { trigger.call }.to raise_error Arachni::Plugin::Error::UnsatisfiedDependency
            end
        end
    end

    describe '#sane_env?' do
        context 'when gem dependencies are met' do
            it 'returns true' do
                @plugins.sane_env?( @plugins['default'] ).should == true
            end
        end
        context 'when gem dependencies are not met' do
            it 'returns a hash with errors' do
                @plugins.sane_env?( @plugins['bad'] ).include?( :gem_errors ).should be_true
                @plugins.delete( 'bad' )
            end
        end
    end

    describe '#create' do
        it 'returns a plugin instance' do
            @plugins.create( 'default' ).instance_of?( @plugins['default'] ).should be_true
        end
    end

    describe '#busy?' do
        context 'when plugins are running' do
            it 'returns true' do
                @plugins.run
                @plugins.busy?.should be_true
                @plugins.block
            end
        end
        context 'when plugins have finished' do
            it 'returns false' do
                @plugins.run
                @plugins.block
                @plugins.busy?.should be_false
            end
        end
    end

    describe '#job_names' do
        context 'when plugins are running' do
            it 'returns the names of the running plugins' do
                @plugins.run
                @plugins.job_names.should == @plugins.keys
                @plugins.block
            end
        end
        context 'when plugins have finished' do
            it 'returns an empty array' do
                @plugins.run
                @plugins.block
                @plugins.job_names.should be_empty
            end
        end
    end

    describe '#jobs' do
        context 'when plugins are running' do
            it 'returns the names of the running plugins' do
                @plugins.run
                @plugins.jobs.first.instance_of?( Thread ).should be_true
                @plugins.block
            end
        end
        context 'when plugins have finished' do
            it 'returns an empty array' do
                @plugins.run
                @plugins.block
                @plugins.jobs.should be_empty
            end
        end
    end

    describe '#kill' do
        context 'when a plugin is running' do
            it 'kills a running plugin' do
                @plugins.load( 'loop' )
                @plugins.run
                ret = @plugins.kill( 'loop' )
                @plugins.block

                ret.should be_true
                @plugins.delete( 'loop' )
            end
        end

        context 'when plugin is not running' do
            it 'returns false' do
                @plugins.run
                @plugins.block
                @plugins.kill( 'default' ).should be_false
            end
        end
    end

    describe '#get' do
        context 'when a plugin is running' do
            it 'returns its thread' do
                @plugins.load( 'loop' )
                @plugins.run
                @plugins.get( 'loop' ).should be_kind_of Thread
                @plugins.kill( 'loop' )
                @plugins.block

                @plugins.delete( 'loop' )
            end
        end

        context 'when plugin is not running' do
            it 'returns nil' do
                @plugins.run
                @plugins.block
                @plugins.get( 'default' ).should be_nil
            end
        end
    end

    describe '#results' do
        it "delegates to ##{Arachni::Data::Plugins}#results" do
            Arachni::Data.plugins.results.object_id.should ==
                @plugins.results.object_id
        end
    end

end
