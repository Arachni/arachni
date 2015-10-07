require 'spec_helper'

describe Arachni::OptionGroups::Datastore do
    include_examples 'option_group'
    subject { described_class.new }

    it 'creates attribute accessors on the fly' do
        subject.test = 1
        expect(subject.test).to eq(1)
    end

    describe '#to_h' do
        it 'only includes attributes with accessors' do
            method = :stuff=

            subject.instance_variable_set( :@blah, true )

            value = subject.send( method, 'stuff' )
            expect(subject.to_h).to eq({ method.to_s[0...-1].to_sym => value })
        end
    end

    describe '#update' do
        it 'updates self with the values of the given hash' do
            method = :stuff
            value  = 'stuff'

            subject.update( { method => value } )
            expect(subject.send( method )).to include value
        end

        it 'returns self' do
            expect(subject.update({})).to eq(subject)
        end
    end

    describe '#merge' do
        it 'updates self with the values of the given OptionGroup' do
            method = :stuff
            value  = 'stuff'

            group = described_class.new
            group.update( { method => value } )

            subject.merge( group )
            expect(subject.send( method )).to include value
        end

        it 'returns self' do
            group = described_class.new
            expect(subject.merge( group )).to eq(subject)
        end
    end
end
