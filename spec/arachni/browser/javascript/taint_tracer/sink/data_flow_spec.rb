require 'spec_helper'

describe Arachni::Browser::Javascript::TaintTracer::Sink::DataFlow do
    it_should_behave_like 'sink'

    subject { Factory[:data_flow] }

    %w(function object tainted_argument_index tainted_value taint).each do |m|
        it { is_expected.to respond_to m }
        it { is_expected.to respond_to "#{m}=" }
    end

    it "supports #{Arachni::RPC::Serializer}" do
        expect(subject).to eq(Arachni::RPC::Serializer.deep_clone( subject ))
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        %w(function object tainted_argument_index tainted_value taint).each do |attribute|
            it "includes '#{attribute}'" do
                expect(data[attribute.to_sym]).to eq(subject.send( attribute ))
            end
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        %w(function object tainted_argument_index tainted_value taint).each do |attribute|
            it "restores '#{attribute}'" do
                expect(restored.send( attribute )).to eq(subject.send( attribute ))
            end
        end
    end

    describe '#tainted_argument_value' do
        context 'when there are #arguments' do
            it 'returns the tainted argument' do
                expect(subject.tainted_argument_value).to eq('blah-val')
            end
        end

        context 'when there are no #arguments' do
            it 'returns nil' do
                subject.function.arguments = nil
                expect(subject.tainted_argument_value).to be_nil
            end
        end
    end

    describe '#tainted_argument_name' do
        context 'when there are #arguments' do
            it 'returns the tainted argument' do
                expect(subject.tainted_argument_name).to eq('blah')
            end
        end

        context "when there are are no #{Arachni::Browser::Javascript::TaintTracer::Frame::CalledFunction}#signature_arguments" do
            it 'returns nil' do
                allow(subject.function).to receive(:signature_arguments){ nil }
                expect(subject.tainted_argument_name).to be_nil
            end
        end
    end

    describe '#to_h' do
        it 'returns a hash containing frame data' do
            expect(subject.to_h).to eq(Factory[:data_flow])
        end

        it 'converts #function to hash' do
            expect(subject.to_h[:function]).to eq(Factory[:called_function_data])
        end

        it 'is aliased to #to_hash' do
            expect(subject.to_h).to eq(subject.to_hash)
        end
    end
end
