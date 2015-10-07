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
            expect(state[:suspendable][:options]).to eq({
                my_option: 'updated'
            })
        end

        it 'stores plugin state' do
            expect(state).to include :suspendable
            expect(state[:suspendable][:data]).to eq(1)
        end

        it 'kills the running plugins' do
            expect(subject.jobs).to be_empty
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

            expect(subject.jobs[:suspendable][:instance].options).to eq({
                my_option: 'updated'
            })
        end

        it 'restores plugin state' do
            subject.restore
            expect(subject.jobs[:suspendable][:instance].counter).to eq(2)
        end

        context 'when a loaded plugin has no associated state' do
            it "calls #{Arachni::Plugin::Base}#prepare instead of #{Arachni::Plugin::Base}#restore" do
                subject.state.delete :suspendable
                subject.restore
                expect(subject.jobs[:suspendable][:instance].counter).to eq(1)
            end
        end
    end

    describe '#load_default' do
        it 'loads default plugins' do
            expect(subject).to be_empty
            subject.load_default
            expect(subject.include?( 'default' )).to be_truthy
            subject.clear
        end
        it 'aliased to #load_defaults' do
            expect(subject).to be_empty
            subject.load_defaults
            expect(subject.include?( 'default' )).to be_truthy
        end
    end

    describe '#default' do
        it 'returns the default plugins' do
            expect(subject.default.include?( 'default' )).to be_truthy
        end
        it 'aliased to #defaults' do
            expect(subject.defaults.include?( 'default' )).to be_truthy
        end
    end

    describe '#run' do
        it 'runs loaded plugins' do
            subject.load_default
            subject.run
            subject.block
            expect(subject.results[:default][:results]).to be_truthy
        end
    end

    describe '#schedule' do
        it 'returns scheduled plugins' do
            subject.load_default
            expect(subject.schedule).to eq({
                default: {
                    int_opt: 4
                }
            })
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
                expect(scheduled[0..1].sort).to eq([:p0, :p00].sort)
                expect(scheduled[2]).to eq(:p1)
                expect(scheduled[3..5].sort).to eq([:p22, :p222, :p2].sort)
                expect(scheduled[6..7].sort).to eq([:p_nil, :p_nil2].sort)
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
                expect(subject.sane_env?( subject['default'] )).to eq(true)
            end
        end
        context 'when gem dependencies are not met' do
            it 'returns a hash with errors' do
                expect(subject.sane_env?( subject['bad'] ).include?( :gem_errors )).to be_truthy
                subject.delete( 'bad' )
            end
        end
    end

    describe '#create' do
        it 'returns a plugin instance' do
            expect(subject.create( 'default' ).instance_of?( subject['default'] )).to be_truthy
        end
    end

    describe '#busy?' do
        context 'when plugins are running' do
            it 'returns true' do
                subject.load :wait
                subject.run
                expect(subject.busy?).to be_truthy
                framework.state.running = false
                subject.block
            end
        end
        context 'when plugins have finished' do
            it 'returns false' do
                subject.run
                subject.block
                expect(subject.busy?).to be_falsey
            end
        end
    end

    describe '#job_names' do
        context 'when plugins are running' do
            it 'returns the names of the running plugins' do
                subject.run
                expect(subject.job_names).to eq(subject.keys)
                subject.block
            end
        end
        context 'when plugins have finished' do
            it 'returns an empty array' do
                subject.run
                subject.block
                expect(subject.job_names).to be_empty
            end
        end
    end

    describe '#jobs' do
        context 'when plugins are running' do
            it 'returns the plugins threads' do
                subject.load :wait
                subject.run
                expect(subject.jobs[:wait]).to be_instance_of Thread

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
                expect(subject.jobs).to be_empty
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

                expect(ret).to be_truthy
                subject.delete( 'loop' )
            end
        end

        context 'when plugin is not running' do
            it 'returns false' do
                subject.run
                subject.block
                expect(subject.kill( 'default' )).to be_falsey
            end
        end
    end

    describe '#results' do
        it "delegates to ##{Arachni::Data::Plugins}#results" do
            expect(Arachni::Data.plugins.results.object_id).to eq(
                subject.results.object_id
            )
        end
    end

    describe '#reset' do
        it 'calls #kill' do
            expect(subject).to receive(:killall).at_least(1).times
            subject.reset
        end

        it 'calls #clear' do
            expect(subject).to receive(:clear).at_least(1).times
            subject.reset
        end

        it 'calls .reset' do
            expect(described_class).to receive(:reset).at_least(1).times
            subject.reset
        end
    end

end
