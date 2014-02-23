require 'spec_helper'

describe Arachni::Element::Header do
    it_should_behave_like 'auditable', single_input: true, supports_nulls: false

    subject { described_class.new( url: url, inputs: inputs ) }
    let(:inputs) { { 'input1' => 'value1' } }
    let(:url) { utilities.normalize_url( web_server_url_for( :header ) ) }
    let(:utilities) { Arachni::Utilities }

    it 'is be assigned to Arachni::Header for easy access' do
        Arachni::Header.should == described_class
    end

    it 'retains its assigned inputs' do
        subject.inputs.should == inputs
    end

    describe '#simple' do
        it 'returns the inputs as is' do
            subject.simple.should == inputs
        end
    end

    describe '#mutations' do
        describe :param_flip do
            it 'creates a new header' do
                subject.mutations( 'seed', param_flip: true ).last.
                    inputs.keys.should == %w(seed)
            end
        end

        describe :format do
            it 'does not include NULLs' do
                subject.mutations( 'seed' ).
                    select { |m| m.affected_input_value.include? "\0" }.should be_empty
            end
        end
    end

    describe '#name' do
        it 'returns the header name' do
            subject.name.should == inputs.first.to_a.first
        end
    end

    describe '#value' do
        it 'returns the header value' do
            subject.value.should == inputs.first.to_a.last
        end
    end

    describe '#type' do
        it 'is "header"' do
            subject.type.should == :header
        end
    end

end
