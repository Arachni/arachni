require 'spec_helper'

describe Arachni::Browser::Javascript::TaintTracer::Frame::CalledFunction do

    subject { Factory[:called_function] }

    %w(source name arguments).each do |m|
        it { should respond_to m }
        it { should respond_to "#{m}=" }
    end

    it "supports #{Arachni::RPC::Serializer}" do
        subject.should == Arachni::RPC::Serializer.deep_clone( subject )
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        %w(source name arguments).each do |attribute|
            it "includes '#{attribute}'" do
                data[attribute.to_sym].should == subject.send( attribute )
            end
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        %w(source name arguments).each do |attribute|
            it "restores '#{attribute}'" do
                restored.send( attribute ).should == subject.send( attribute )
            end
        end
    end

    describe '#signature' do
        context 'when #source is available' do
            it 'returns the function signature' do
                subject.signature.should == 'stuff(blah, blooh)'
            end
        end

        context 'when #source is not available' do
            it 'returns nil' do
                subject.source = nil
                subject.signature.should be_nil
            end
        end
    end

    describe '#signature_arguments' do
        context 'when #signature is available' do
            it 'returns the function arguments' do
                subject.signature_arguments.should == %w(blah blooh)
            end
        end

        context 'when #source is not available' do
            it 'returns nil' do
                subject.stub(:signature){ nil }
                subject.signature_arguments.should be_nil
            end
        end
    end

end
