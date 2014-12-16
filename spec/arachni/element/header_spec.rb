require 'spec_helper'

describe Arachni::Element::Header do
    it_should_behave_like 'element'
    it_should_behave_like 'auditable', single_input: true, supports_nulls: false

    def auditable_extract_parameters( resource )
        YAML.load( resource.body )
    end

    def run
        http.run
    end

    subject { described_class.new( url: "#{url}/submit", inputs: inputs ) }
    let(:inputs) { { 'input1' => 'value1' } }
    let(:url) { utilities.normalize_url( web_server_url_for( :header ) ) }
    let(:http) { Arachni::HTTP::Client }
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
        describe :fuzz_names do
            it 'creates a new header' do
                subject.mutations( 'seed', fuzz_names: true ).last.
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

    describe '#valid_input_data?' do
        it 'returns true' do
            subject.valid_input_data?( 'stuff' ).should be_true
        end

        described_class::INVALID_INPUT_DATA.each do |invalid_data|
            context "when the value contains #{invalid_data.inspect}" do
                it 'returns false' do
                    subject.valid_input_data?( "stuff #{invalid_data}" ).should be_false
                end
            end
        end
    end

    describe '.encode' do
        it 'encodes the passed string' do
            v = "stuff \r\n"
            described_class.encode( v ).should == URI.encode( v, "\r\n" )
        end
    end
    describe '#encode' do
        it 'encodes the passed string' do
            v = "stuff \r\n"
            subject.encode( v ).should == described_class.encode( v )
        end
    end

    describe '.decode' do
        it 'URL-decodes the passed string' do
            v = '%25+value%5C+%2B%3D%26%3B'
            described_class.decode( v ).should == URI.decode( v )
        end
    end
    describe '#decode' do
        it 'URL-decodes the passed string' do
            v = '%25+value%5C+%2B%3D%26%3B'
            subject.decode( v ).should == described_class.decode( v )
        end
    end

    describe '#type' do
        it 'is "header"' do
            subject.type.should == :header
        end
    end

end
