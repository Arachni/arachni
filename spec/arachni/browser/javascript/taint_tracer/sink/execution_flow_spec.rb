require 'spec_helper'

describe Arachni::Browser::Javascript::TaintTracer::Sink::ExecutionFlow do
    it_should_behave_like 'sink'

    subject { Factory[:execution_flow] }

    %w(data).each do |m|
        it { is_expected.to respond_to m }
        it { is_expected.to respond_to "#{m}=" }
    end

    it "supports #{Arachni::RPC::Serializer}" do
        expect(subject).to eq(Arachni::RPC::Serializer.deep_clone( subject ))
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        %w(data).each do |attribute|
            it "includes '#{attribute}'" do
                expect(data[attribute.to_sym]).to eq(subject.send( attribute ))
            end
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        %w(data).each do |attribute|
            it "restores '#{attribute}'" do
                expect(restored.send( attribute )).to eq(subject.send( attribute ))
            end
        end
    end

    describe '#to_h' do
        it 'returns a hash containing frame data' do
            expect(subject.to_h).to eq(Factory[:execution_flow])
        end

        it 'is aliased to #to_hash' do
            expect(subject.to_h).to eq(subject.to_hash)
        end
    end
end
