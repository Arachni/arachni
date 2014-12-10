require 'spec_helper'

describe Arachni::Element::XML do
    inputtable_source = '<input1>value1</input1><input2>value2</input2>'

    # it_should_behave_like 'element'
    # it_should_behave_like 'auditable', inputs: described_class.parse_inputs( inputtable_source )

    def auditable_extract_parameters( resource )
        described_class.parse_inputs( resource.body )
    end

    def run
        http.run
    end

    before :each do
        reset_options
    end

    subject { described_class.new( url: "#{url}submit", source: source ) }
    let(:auditable) { inputtable }
    let(:inputtable) do
        described_class.new(
            url:      "#{url}submit",
            source: '<input1>value1</input1><input2>value2</input2>'
        )
    end

    let(:inputs) { described_class.parse_inputs( source ) }
    let(:source) do
        <<EOXML
 <bookstore>

<book category="COOKING">
  <title lang="en">Everyday Italian</title>
  <author>Giada De Laurentiis</author>
  <year>2005</year>
  <price>30.00</price>
</book>

<book category="CHILDREN">
  <title lang="en">Harry Potter</title>
  <author>J K. Rowling</author>
  <year>2005</year>
  <price>29.99</price>
</book>

<book category="WEB">
  <title lang="en">XQuery Kick Start</title>
  <author>James McGovern</author>
  <author>Per Bothner</author>
  <author>Kurt Cagle</author>
  <author>James Linn</author>
  <author>Vaidyanathan Nagarajan</author>
  <year>2003</year>
  <price>49.99</price>
</book>

<book category="WEB">
  <title lang="en">Learning XML</title>
  <author>Erik T. Ray</author>
  <year>2003</year>
  <price>39.95</price>
</book>

</bookstore>
EOXML
    end
    let(:url) { utilities.normalize_url( web_server_url_for( :xml ) ) }
    let(:http) { Arachni::HTTP::Client }
    let(:utilities) { Arachni::Utilities }

    it 'is assigned to Arachni::Link for easy access' do
        Arachni::XML.should == described_class
    end

    describe '#initialize' do
        context "when the 'source' is missing" do
            it 'fails' do
                expect do
                    described_class.new( url: "#{url}submit" )
                end.to raise_error described_class::Error::MissingSource
            end
        end
    end

    describe '#simple' do
        it 'should return a simplified version as a hash' do
            subject.simple.should == { subject.action => subject.inputs }
        end
    end

    describe '#to_xml' do
        it 'returns the updated XML' do
            subject.inputs.each do |name, _|
                s = subject.dup
                s[name] = "#{name} value"
                Nokogiri::XML(s.to_xml).css(name).first.content.should == "#{name} value"
            end
        end
    end

    describe '#to_s' do
        it 'returns #to_xml' do
            subject.to_s.should == subject.to_xml
        end
    end

    describe '#type' do
        it 'should be "link"' do
            subject.type.should == :xml
        end
    end

    describe '#to_rpc_data' do
        it "includes 'source'" do
            subject.to_rpc_data['source'].should == source
        end
    end

    describe '.from_request' do
        subject { described_class.from_request( url, request ) }

        context 'when the request has an XML body' do
            let(:request) do
                Arachni::HTTP::Request.new(
                    url:    "#{url}-1",
                    method: :post,
                    body:   source
                )
            end

            it 'parses a request into an element' do
                subject.url.should    == url
                subject.action.should == request.url
                subject.source.should == request.body
                subject.method.should == request.method
            end
        end

        context 'when the body is empty' do
            let(:request) do
                Arachni::HTTP::Request.new(
                    url:    "#{url}-1",
                    method: :post
                )
            end

            it 'returns nil' do
                subject.should be_nil
            end
        end

        context 'when there are no inputs' do
            let(:request) do
                Arachni::HTTP::Request.new(
                    url:    "#{url}-1",
                    method: :post,
                    body:   'stuff'
                )
            end

            it 'returns nil' do
                subject.should be_nil
            end
        end
    end

    describe '.parse_inputs' do
        it 'parses an XML document into a hash of inputs'
    end

    describe '.encode' do
        it 'returns the string as is' do
            described_class.encode( 'stuff' ).should == 'stuff'
        end
    end
    describe '#encode' do
        it 'returns the string as is' do
            subject.encode( 'stuff' ).should == 'stuff'
        end
    end

    describe '.decode' do
        it 'returns the string as is' do
            described_class.decode( 'stuff' ).should == 'stuff'
        end
    end
    describe '#decode' do
        it 'returns the string as is' do
            subject.decode( 'stuff' ).should == 'stuff'
        end
    end

end
