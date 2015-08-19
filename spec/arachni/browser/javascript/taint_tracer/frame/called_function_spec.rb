require 'spec_helper'

describe Arachni::Browser::Javascript::TaintTracer::Frame::CalledFunction do

    subject { Factory[:called_function] }

    %w(source name arguments).each do |m|
        it { is_expected.to respond_to m }
        it { is_expected.to respond_to "#{m}=" }
    end

    it "supports #{Arachni::RPC::Serializer}" do
        expect(subject).to eq(Arachni::RPC::Serializer.deep_clone( subject ))
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        %w(source name arguments).each do |attribute|
            it "includes '#{attribute}'" do
                expect(data[attribute.to_sym]).to eq(subject.send( attribute ))
            end
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        %w(source name arguments).each do |attribute|
            it "restores '#{attribute}'" do
                expect(restored.send( attribute )).to eq(subject.send( attribute ))
            end
        end
    end

    describe '#signature' do
        context 'when #source is available' do
            it 'returns the function signature' do
                expect(subject.signature).to eq('stuff(blah, blooh)')
            end
        end

        context 'when #source is not available' do
            it 'returns nil' do
                subject.source = nil
                expect(subject.signature).to be_nil
            end
        end
    end

    describe '#signature_arguments' do
        context 'when #signature is available' do
            it 'returns the function arguments' do
                expect(subject.signature_arguments).to eq(%w(blah blooh))
            end
        end

        context 'when #source is not available' do
            it 'returns nil' do
                allow(subject).to receive(:signature){ nil }
                expect(subject.signature_arguments).to be_nil
            end
        end
    end

    describe '#to_h' do
        it 'converts self to a hash' do
            expect(subject.to_h).to eq(Factory[:called_function_data])
        end
    end
end
