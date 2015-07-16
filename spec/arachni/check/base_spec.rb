require 'spec_helper'

describe Arachni::Check::Base do
    before( :each ) do
        reset_options

        @framework = Arachni::Framework.new
        @framework.state.running = true

        @framework.plugins.load_default
    end

    after( :each ) do
        @framework.reset
        Arachni::Options.reset
        described_class.clear_info_cache
    end

    subject { described_class.new( Factory[:page], framework ) }
    let(:framework) { @framework }

    describe '#session' do
        it "returns #{Arachni::Framework}#session" do
            subject.session.should == framework.session
        end
    end

    describe '#plugins' do
        it "returns #{Arachni::Framework}#plugins" do
            subject.plugins.should == framework.plugins
        end
    end

    describe '#has_platforms?' do
        context 'when platforms are provided' do
            before do
                described_class.stub(:info) { { platforms: [ :unix ] } }
            end

            it 'returns true' do
                described_class.has_platforms?.should be_true
            end
        end

        context 'when platforms are not provided' do
            before do
                described_class.stub(:info) { { platforms: [] } }
            end

            it 'returns false' do
                described_class.has_platforms?.should be_false
            end
        end
    end

    describe '#has_exempt_platforms?' do
        context 'when exempt platforms are provided' do
            before do
                described_class.stub(:info) { { exempt_platforms: [ :unix ] } }
            end

            it 'returns true' do
                described_class.has_exempt_platforms?.should be_true
            end
        end

        context 'when exempt platforms are not provided' do
            before do
                described_class.stub(:info) { { exempt_platforms: [] } }
            end

            it 'returns false' do
                described_class.has_exempt_platforms?.should be_false
            end
        end
    end

    describe '#supports_platforms?' do
        context 'when empty platforms are given' do
            it 'returns true' do
                described_class.supports_platforms?([]).should be_true
            end
        end

        context 'when no supported platforms are declared' do
            before do
                described_class.stub(:info) { { platforms: [] } }
            end

            it 'returns true' do
                described_class.supports_platforms?([]).should be_true
            end
        end

        context 'when any of the given platforms are supported' do
            before do
                described_class.stub(:info) { { platforms: [:php] } }
            end

            it 'returns true' do
                described_class.supports_platforms?([:unix, :php]).should be_true
            end
        end

        context 'when any of the given platforms are exempt' do
            before do
                described_class.stub(:info) { { exempt_platforms: [:php] } }
            end

            it 'returns false' do
                described_class.supports_platforms?([:unix, :php]).should be_false
            end
        end

        context 'when a parent of any of the given platforms is supported' do
            before do
                described_class.stub(:info) { { platforms: [:unix] } }
            end

            it 'returns true' do
                described_class.supports_platforms?([:linux]).should be_true
            end
        end

        context 'when a parent of any of the given platforms is exempt' do
            before do
                described_class.stub(:info) { { exempt_platforms: [:unix] } }
            end

            it 'returns false' do
                described_class.supports_platforms?([:linux]).should be_false
            end
        end


        context 'when a child of any of the given platforms is supported' do
            before do
                described_class.stub(:info) { { platforms: [:linux] } }
            end

            it 'returns true' do
                described_class.supports_platforms?([:unix]).should be_true
            end
        end

        context 'when a child of any of the given platforms is exempt' do
            before do
                described_class.stub(:info) { { exempt_platforms: [:linux] } }
            end

            it 'returns false' do
                described_class.supports_platforms?([:unix]).should be_false
            end
        end

        context 'when none of the given platforms are not provided' do
            before do
                described_class.stub(:info) { { platforms: [:windows] } }
            end

            it 'returns false' do
                described_class.supports_platforms?([:unix]).should be_false
            end
        end

        context 'when none of the given platforms are exempt' do
            before do
                described_class.stub(:info) { { exempt_platforms: [:windows] } }
            end

            it 'returns true' do
                described_class.supports_platforms?([:unix]).should be_true
            end
        end

        context 'when any of the given platforms are exempt' do
            before do
                described_class.stub(:info) { { exempt_platforms: [:windows, :linux] } }
            end

            it 'returns false' do
                described_class.supports_platforms?([:unix]).should be_false
            end
        end

        context 'when a platforms of different type is exempt' do
            before do
                described_class.stub(:info) { { exempt_platforms: [:windows] } }
            end

            it 'returns true' do
                described_class.supports_platforms?([:ruby]).should be_true
            end
        end

    end
end
