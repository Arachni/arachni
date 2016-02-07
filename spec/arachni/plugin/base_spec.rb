require 'spec_helper'

describe Arachni::Plugin::Base do
    before( :each ) do
        reset_options

        Arachni::Options.url = web_server_url_for(:framework)
        @framework = Arachni::Framework.new
        @framework.state.running = true

        @framework.plugins.load_default
    end

    after( :each ) do
        @framework.reset
        Arachni::Options.reset
    end

    subject { described_class.new( framework, {} ) }
    let(:framework) { @framework }

    describe '.distributable?' do
        it 'returns false' do
            expect(described_class).not_to be_distributable
        end

        context 'when the distributable flag has been set' do
            it 'returns true' do
                described_class.distributable
                expect(described_class).to be_distributable
            end
        end
    end

    describe '.is_distributable' do
        it 'sets the distributable? flag' do
            described_class.is_distributable
            expect(described_class).to be_distributable
        end
    end

    describe '#info' do
        it 'returns .info' do
            expect(subject.info).to eq(described_class.info)
        end
    end

    describe '#session' do
        it "returns #{Arachni::Framework}#session" do
            expect(subject.session).to eq(framework.session)
        end
    end

    describe '#http' do
        it "returns #{Arachni::Framework}#http" do
            expect(subject.http).to eq(framework.http)
        end
    end

    describe '#framework_pause' do
        it 'pauses the framework' do
            expect(framework).to receive(:pause)
            subject.framework_pause
        end
    end

    describe '#framework_resume' do
        it 'resumes the framework' do
            framework.run

            subject.framework_pause

            expect(framework).to receive(:resume)
            subject.framework_resume
        end
    end

    describe '#wait_while_framework_running' do
        it 'blocks while the framework runs' do
            expect(framework).to be_running

            q = Queue.new
            Thread.new do
                subject.wait_while_framework_running
                q << nil
            end

            @framework.state.running = false

            Timeout.timeout 2 do
                q.pop
            end

            expect(framework).not_to be_running
        end
    end

end
