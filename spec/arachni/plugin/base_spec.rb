require 'spec_helper'

describe Arachni::Plugin::Base do
    before( :each ) do
        reset_options

        @framework = Arachni::Framework.new
        @framework.state.running = true

        @framework.plugins.load_default
    end

    after( :each ) do
        @framework.reset
        Arachni::Options.reset
    end

    subject { Arachni::Plugin::Base.new( framework, {} ) }
    let(:framework) { @framework }

    describe '.distributable?' do
        it 'returns false' do
            described_class.should_not be_distributable
        end

        context 'when the distributable flag has been set' do
            it 'returns true' do
                described_class.distributable
                described_class.should be_distributable
            end
        end
    end

    describe '.is_distributable' do
        it 'sets the distributable? flag' do
            described_class.is_distributable
            described_class.should be_distributable
        end
    end

    describe '#info' do
        it 'returns .info' do
            subject.info.should == described_class.info
        end
    end

    describe '#session' do
        it "returns #{Arachni::Framework}#session" do
            subject.session.should == framework.session
        end
    end

    describe '#http' do
        it "returns #{Arachni::Framework}#http" do
            subject.http.should == framework.http
        end
    end

    describe '#framework_pause' do
        it 'pauses the framework' do
            framework.should receive(:pause)
            subject.framework_pause
        end
    end

    describe '#framework_resume' do
        it 'resumes the framework' do
            framework.run

            subject.framework_pause

            framework.should receive(:resume)
            subject.framework_resume
        end
    end

    describe '#wait_while_framework_running' do
        it 'blocks while the framework runs' do
            framework.should be_running

            q = Queue.new
            Thread.new do
                subject.wait_while_framework_running
                q << nil
            end

            @framework.state.running = false

            Timeout.timeout 2 do
                q.pop
            end

            framework.should_not be_running
        end
    end

end
