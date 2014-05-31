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

end
