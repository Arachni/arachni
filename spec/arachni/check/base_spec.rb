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
            expect(subject.session).to eq(framework.session)
        end
    end

    describe '#plugins' do
        it "returns #{Arachni::Framework}#plugins" do
            expect(subject.plugins).to eq(framework.plugins)
        end
    end

    describe '#has_platforms?' do
        context 'when platforms are provided' do
            before do
                allow(described_class).to receive(:info) { { platforms: [ :unix ] } }
            end

            it 'returns true' do
                expect(described_class.has_platforms?).to be_truthy
            end
        end

        context 'when platforms are not provided' do
            before do
                allow(described_class).to receive(:info) { { platforms: [] } }
            end

            it 'returns false' do
                expect(described_class.has_platforms?).to be_falsey
            end
        end
    end

    describe '#has_exempt_platforms?' do
        context 'when exempt platforms are provided' do
            before do
                allow(described_class).to receive(:info) { { exempt_platforms: [ :unix ] } }
            end

            it 'returns true' do
                expect(described_class.has_exempt_platforms?).to be_truthy
            end
        end

        context 'when exempt platforms are not provided' do
            before do
                allow(described_class).to receive(:info) { { exempt_platforms: [] } }
            end

            it 'returns false' do
                expect(described_class.has_exempt_platforms?).to be_falsey
            end
        end
    end

    describe '#supports_platforms?' do
        context 'when empty platforms are given' do
            it 'returns true' do
                expect(described_class.supports_platforms?([])).to be_truthy
            end
        end

        context 'when no supported platforms are declared' do
            before do
                allow(described_class).to receive(:info) { { platforms: [] } }
            end

            it 'returns true' do
                expect(described_class.supports_platforms?([])).to be_truthy
            end
        end

        context 'when any of the given platforms are supported' do
            before do
                allow(described_class).to receive(:info) { { platforms: [:php] } }
            end

            it 'returns true' do
                expect(described_class.supports_platforms?([:unix, :php])).to be_truthy
            end
        end

        context 'when any of the given platforms are exempt' do
            before do
                allow(described_class).to receive(:info) { { exempt_platforms: [:php] } }
            end

            it 'returns false' do
                expect(described_class.supports_platforms?([:unix, :php])).to be_falsey
            end
        end

        context 'when a parent of any of the given platforms is supported' do
            before do
                allow(described_class).to receive(:info) { { platforms: [:unix] } }
            end

            it 'returns true' do
                expect(described_class.supports_platforms?([:linux])).to be_truthy
            end
        end

        context 'when a parent of any of the given platforms is exempt' do
            before do
                allow(described_class).to receive(:info) { { exempt_platforms: [:unix] } }
            end

            it 'returns false' do
                expect(described_class.supports_platforms?([:linux])).to be_falsey
            end
        end


        context 'when a child of any of the given platforms is supported' do
            before do
                allow(described_class).to receive(:info) { { platforms: [:linux] } }
            end

            it 'returns true' do
                expect(described_class.supports_platforms?([:unix])).to be_truthy
            end
        end

        context 'when a child of any of the given platforms is exempt' do
            before do
                allow(described_class).to receive(:info) { { exempt_platforms: [:linux] } }
            end

            it 'returns false' do
                expect(described_class.supports_platforms?([:unix])).to be_falsey
            end
        end

        context 'when none of the given platforms are not provided' do
            before do
                allow(described_class).to receive(:info) { { platforms: [:windows] } }
            end

            it 'returns false' do
                expect(described_class.supports_platforms?([:unix])).to be_falsey
            end
        end

        context 'when none of the given platforms are exempt' do
            before do
                allow(described_class).to receive(:info) { { exempt_platforms: [:windows] } }
            end

            it 'returns true' do
                expect(described_class.supports_platforms?([:unix])).to be_truthy
            end
        end

        context 'when any of the given platforms are exempt' do
            before do
                allow(described_class).to receive(:info) { { exempt_platforms: [:windows, :linux] } }
            end

            it 'returns false' do
                expect(described_class.supports_platforms?([:unix])).to be_falsey
            end
        end

        context 'when a platforms of different type is exempt' do
            before do
                allow(described_class).to receive(:info) { { exempt_platforms: [:windows] } }
            end

            it 'returns true' do
                expect(described_class.supports_platforms?([:ruby])).to be_truthy
            end
        end

    end
end
