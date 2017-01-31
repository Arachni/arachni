require 'spec_helper'

describe Arachni::Element::Header do
    it_should_behave_like 'element'

    it_should_behave_like 'with_auditor'

    it_should_behave_like 'submittable'
    it_should_behave_like 'inputtable', single_input:   true
    it_should_behave_like 'mutable',    supports_nulls: false
    it_should_behave_like 'auditable',  supports_nulls: false
    it_should_behave_like 'buffered_auditable'
    it_should_behave_like 'line_buffered_auditable'

    before :each do
        @framework ||= Arachni::Framework.new
        @auditor     = Auditor.new( Arachni::Page.from_url( url ), @framework )
    end

    after :each do
        @framework.reset
        reset_options
    end

    let(:auditor) { @auditor }

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
        expect(Arachni::Header).to eq(described_class)
    end

    it 'retains its assigned inputs' do
        expect(subject.inputs).to eq(inputs)
    end

    describe '#simple' do
        it 'returns the inputs as is' do
            expect(subject.simple).to eq(inputs)
        end
    end

    describe '#mutations' do
        describe ':parameter_names' do
            it 'creates a new header' do
                expect(subject.mutations( 'seed', parameter_names: true ).last.
                    inputs.keys).to eq(%w(seed))
            end
        end

        describe ':format' do
            it 'does not include NULLs' do
                expect(subject.mutations( 'seed' ).
                    select { |m| m.affected_input_value.include? "\0" }).to be_empty
            end
        end
    end

    describe '#name' do
        it 'returns the header name' do
            expect(subject.name).to eq(inputs.first.to_a.first)
        end
    end

    describe '#value' do
        it 'returns the header value' do
            expect(subject.value).to eq(inputs.first.to_a.last)
        end
    end

    describe '#valid_input_data?' do
        it 'returns true' do
            expect(subject.valid_input_data?( 'stuff' )).to be_truthy
        end

        described_class::INVALID_INPUT_DATA.each do |invalid_data|
            context "when the value contains #{invalid_data.inspect}" do
                it 'returns false' do
                    expect(subject.valid_input_data?( "stuff #{invalid_data}" )).to be_falsey
                end
            end
        end
    end

    describe '.encode' do
        it 'encodes the passed string' do
            v = "stuff \r\n"
            expect(described_class.encode( v )).to eq(URI.encode( v, "\r\n" ))
        end
    end
    describe '#encode' do
        it 'encodes the passed string' do
            v = "stuff \r\n"
            expect(subject.encode( v )).to eq(described_class.encode( v ))
        end
    end

    describe '.decode' do
        it 'URL-decodes the passed string' do
            v = '%25+value%5C+%2B%3D%26%3B'
            expect(described_class.decode( v )).to eq(URI.decode( v ))
        end
    end
    describe '#decode' do
        it 'URL-decodes the passed string' do
            v = '%25+value%5C+%2B%3D%26%3B'
            expect(subject.decode( v )).to eq(described_class.decode( v ))
        end
    end

    describe '#type' do
        it 'is "header"' do
            expect(subject.type).to eq(:header)
        end
    end

end
