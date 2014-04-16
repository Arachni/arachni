require 'spec_helper'

describe Arachni::Serializer do
    subject { described_class }

    describe '.dump' do
        context 'when the object responds to #to_msgpack' do
            it 'returns its return value' do
                object = [1,2,:test]
                subject.dump( object ).should == object.to_msgpack
            end
        end

        context 'when the object does not respond to #to_msgpack' do
            it 'uses #to_serializer_data' do
                object = Object.new
                object.should receive(:to_serializer_data)
                subject.dump( object )
            end
        end
    end
end
