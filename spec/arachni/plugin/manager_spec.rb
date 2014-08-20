require 'spec_helper'

describe Arachni::Plugin::Manager do
    before( :each ) do
        @framework = Arachni::Framework.new
        @framework.state.running = true
    end

    after( :each ) do
        @framework.reset
        reset_options
    end

    subject { @framework.plugins }
    let(:framework) { @framework }

    describe '#suspend' do
        before :each do
            Arachni::Options.plugins['suspendable'] = {
                'my_option' => 'my value'
            }

            subject.load :suspendable
            subject.run

            sleep 2
            subject.suspend
        end
        let(:state) { Arachni::State.plugins.runtime }

        it 'stores plugin options' do
            state[:suspendable][:options].should == {
                my_option: 'updated'
            }
        end

        it 'stores plugin state' do
            state.should include :suspendable
            state[:suspendable][:data].should == 1
        end

        it 'kills the running plugins' do
            subject.jobs.should be_empty
        end
    end

    describe '#restore' do
        before :each do
            Arachni::Options.plugins['suspendable'] = {
                'my_option' => 'my value'
            }

            subject.load :suspendable
            subject.run

            sleep 2
            subject.suspend

            subject.killall
        end
        let(:state) { Arachni::State.plugins.runtime }

        it 'restores plugin options' do
            subject.restore

            subject.jobs[:suspendable][:instance].options.should == {
                my_option: 'updated'
            }
        end

        it 'restores plugin state' do
            subject.restore
            subject.jobs[:suspendable][:instance].counter.should == 2
        end

        context 'when a loaded plugin has no associated state' do
            it "calls #{Arachni::Plugin::Base}#prepare instead of #{Arachni::Plugin::Base}#restore" do
                subject.state.delete :suspendable
                subject.restore
                subject.jobs[:suspendable][:instance].counter.should == 1
            end
        end
    end

    describe '#load_default' do
        it 'loads default plugins' do
            subject.should be_empty
            subject.load_default
            subject.include?( 'default' ).should be_true
            subject.clear
        end
        it 'aliased to #load_defaults' do
            subject.should be_empty
            subject.load_defaults
            subject.include?( 'default' ).should be_true
        end
    end

    describe '#default' do
        it 'returns the default plugins' do
            subject.default.include?( 'default' ).should be_true
        end
        it 'aliased to #defaults' do
            subject.defaults.include?( 'default' ).should be_true
        end
    end

    describe '#run' do
        it 'runs loaded plugins' do
            subject.load_default
            subject.run
            subject.block
            subject.results[:default][:results].should be_true
        end
    end

    describe '#schedule' do
        it 'returns scheduled plugins' do
            subject.load_default
            subject.schedule.should == {
                default: {
                    int_opt: 4
                }
            }
        end

        context 'when plugins have :priority' do
            before( :each ) do
                @framework.reset

                Arachni::Options.paths.plugins = "#{fixtures_path}/plugins_with_priorities/"

                @framework = Arachni::Framework.new
                @framework.state.running = true
            end

            it 'orders them based on priority' do
                subject.load '*'
                scheduled = subject.schedule.keys
                scheduled[0..1].sort.should == [:p0, :p00].sort
                scheduled[2].should == :p1
                scheduled[3..5].sort.should == [:p22, :p222, :p2].sort
                scheduled[6..7].sort.should == [:p_nil, :p_nil2].sort
            end
        end

        context 'when gem dependencies are not met' do
            it "raises #{Arachni::Plugin::Error::UnsatisfiedDependency}" do
                subject.load :bad
                expect { subject.schedule }.to raise_error Arachni::Plugin::Error::UnsatisfiedDependency
            end
        end
    end

    describe '#sane_env?' do
        context 'when gem dependencies are met' do
            it 'returns true' do
                subject.sane_env?( subject['default'] ).should == true
            end
        end
        context 'when gem dependencies are not met' do
            it 'returns a hash with errors' do
                subject.sane_env?( subject['bad'] ).include?( :gem_errors ).should be_true
                subject.delete( 'bad' )
            end
        end
    end

    describe '#create' do
        it 'returns a plugin instance' do
            subject.create( 'default' ).instance_of?( subject['default'] ).should be_true
        end
    end

    describe '#busy?' do
        context 'when plugins are running' do
            it 'returns true' do
                subject.load :wait
                subject.run
                subject.busy?.should be_true
                framework.state.running = false
                subject.block
            end
        end
        context 'when plugins have finished' do
            it 'returns false' do
                subject.run
                subject.block
                subject.busy?.should be_false
            end
        end
    end

    describe '#job_names' do
        context 'when plugins are running' do
            it 'returns the names of the running plugins' do
                subject.run
                subject.job_names.should == subject.keys
                subject.block
            end
        end
        context 'when plugins have finished' do
            it 'returns an empty array' do
                subject.run
                subject.block
                subject.job_names.should be_empty
            end
        end
    end

    describe '#jobs' do
        context 'when plugins are running' do
            it 'returns the plugins threads' do
                subject.load :wait
                subject.run
                subject.jobs[:wait].should be_instance_of Thread

                framework.state.running = false

                subject.block
            end
        end
        context 'when plugins have finished' do
            it 'returns an empty hash' do
                subject.load :wait
                subject.run
                framework.state.running = false

                subject.block
                subject.jobs.should be_empty
            end
        end
    end

    describe '#kill' do
        context 'when a plugin is running' do
            it 'kills a running plugin' do
                subject.load( 'loop' )
                subject.run
                ret = subject.kill( 'loop' )
                subject.block

                ret.should be_true
                subject.delete( 'loop' )
            end
        end

        context 'when plugin is not running' do
            it 'returns false' do
                subject.run
                subject.block
                subject.kill( 'default' ).should be_false
            end
        end
    end

    describe '#results' do
        it "delegates to ##{Arachni::Data::Plugins}#results" do
            Arachni::Data.plugins.results.object_id.should ==
                subject.results.object_id
        end
    end

    describe '#reset' do
        it 'calls #kill' do
            subject.should receive(:killall).at_least(1).times
            subject.reset
        end

        it 'calls #clear' do
            subject.should receive(:clear).at_least(1).times
            subject.reset
        end

        it 'calls .reset' do
            described_class.should receive(:reset).at_least(1).times
            subject.reset
        end
    end

end
