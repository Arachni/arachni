require 'spec_helper'

describe Arachni::OptionGroups::Datastore do
    include_examples 'option_group'
    subject { described_class.new }

    it 'creates attribute accessors on the fly' do
        subject.test = 1
        subject.test.should == 1
    end

    describe '#to_h' do
        it 'only includes attributes with accessors' do
            method = :stuff=

            subject.instance_variable_set( :@blah, true )

            value = subject.send( method, 'stuff' )
            subject.to_h.should == { method.to_s[0...-1].to_sym => value }
        end
    end

    describe '#update' do
        it 'updates self with the values of the given hash' do
            method = :stuff
            value  = 'stuff'

            subject.update( { method => value } )
            subject.send( method ).should include value
        end

        it 'returns self' do
            subject.update({}).should == subject
        end
    end

    describe '#merge' do
        it 'updates self with the values of the given OptionGroup' do
            method = :stuff
            value  = 'stuff'

            group = described_class.new
            group.update( { method => value } )

            subject.merge( group )
            subject.send( method ).should include value
        end

        it 'returns self' do
            group = described_class.new
            subject.merge( group ).should == subject
        end
    end
end
