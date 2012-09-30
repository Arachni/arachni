require_relative '../../spec_helper'

describe Arachni::Plugin::Manager do
    before( :all ) do
        opts = Arachni::Options.instance
        opts.dir['plugins'] = spec_path + 'fixtures/plugins/'

        @plugins = Arachni::Framework.new( Arachni::Options.instance ).plugins
    end

    after( :all ) { @plugins.clear }

    describe '#load_default' do
        it 'should load default plugins' do
            @plugins.should be_empty
            @plugins.load_default
            @plugins.include?( 'default' ).should be_true
            @plugins.clear
        end
        it 'should be aliased to #load_defaults' do
            @plugins.should be_empty
            @plugins.load_defaults
            @plugins.include?( 'default' ).should be_true
        end
    end

    describe '#default' do
        it 'should return the default plugins' do
            @plugins.default.include?( 'default' ).should be_true
        end
        it 'should be aliased to #defaults' do
            @plugins.defaults.include?( 'default' ).should be_true
        end
    end

    describe '#run' do
        context 'when gem dependencies are met' do
            it 'should run loaded plugins' do
                @plugins.run
                @plugins.block
                @plugins.results['default'][:results].should be_true
            end
        end
        context 'when gem dependencies are not met' do
            it 'should raise exception' do
                raised = false
                begin
                    @plugins.load( 'bad' )
                    @plugins.run
                    @plugins.block
                rescue
                    raised = true
                end
                raised.should be_true
            end
        end
    end

    describe '#sane_env?' do
        context 'when gem dependencies are met' do
            it 'should return true' do
                @plugins.sane_env?( @plugins['default'] ).should == true
            end
        end
        context 'when gem dependencies are not met' do
            it 'should raise exception' do
                @plugins.sane_env?( @plugins['bad'] ).include?( :gem_errors ).should be_true
                @plugins.delete( 'bad' )
            end
        end
    end

    describe '#create' do
        it 'should return a plugin instance' do
            @plugins.create( 'default' ).instance_of?( @plugins['default'] ).should be_true
        end
    end

    describe '#busy?' do
        context 'when plugins are running' do
            it 'should return true' do
                @plugins.run
                @plugins.busy?.should be_true
                @plugins.block
            end
        end
        context 'when plugins have finished' do
            it 'should return false' do
                @plugins.run
                @plugins.block
                @plugins.busy?.should be_false
            end
        end
    end

    describe '#job_names' do
        context 'when plugins are running' do
            it 'should return the names of the running plugins' do
                @plugins.run
                @plugins.job_names.should == @plugins.keys
                @plugins.block
            end
        end
        context 'when plugins have finished' do
            it 'should return an empty array' do
                @plugins.run
                @plugins.block
                @plugins.job_names.should be_empty
            end
        end
    end

    describe '#jobs' do
        context 'when plugins are running' do
            it 'should return the names of the running plugins' do
                @plugins.run
                @plugins.jobs.first.instance_of?( Thread ).should be_true
                @plugins.block
            end
        end
        context 'when plugins have finished' do
            it 'should return an empty array' do
                @plugins.run
                @plugins.block
                @plugins.jobs.should be_empty
            end
        end
    end

    describe '#kill' do
        context 'when a plugin is running' do
            it 'should kill a running plugin' do
                @plugins.load( 'loop' )
                @plugins.run
                ret = @plugins.kill( 'loop' )
                @plugins.block

                ret.should be_true
                @plugins.delete( 'loop' )
            end
        end

        context 'when plugin is not running' do
            it 'should return false' do
                @plugins.run
                @plugins.block
                @plugins.kill( 'default' ).should be_false
            end
        end
    end

    describe '#get' do
        context 'when a plugin is running' do
            it 'should return its thread' do
                @plugins.load( 'loop' )
                @plugins.run
                @plugins.get( 'loop' ).is_a?( Thread ).should be_true
                @plugins.kill( 'loop' )
                @plugins.block

                @plugins.delete( 'loop' )
            end
        end

        context 'when plugin is not running' do
            it 'should return nil' do
                @plugins.run
                @plugins.block
                @plugins.get( 'default' ).should be_nil
            end
        end
    end

end
