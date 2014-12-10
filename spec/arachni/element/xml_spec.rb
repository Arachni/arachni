require 'spec_helper'

describe Arachni::Element::XML do
    inputtable_source = '<input1>value1</input1><input2>value2</input2>'

    it_should_behave_like 'element'
    it_should_behave_like 'auditable', inputs: described_class.parse_inputs( inputtable_source )

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
        describe ':source' do
            it 'parses it into #inputs' do
                subject.inputs.should == described_class.parse_inputs( source )
            end

            context 'when missing' do
                it 'fails' do
                    expect do
                        described_class.new( url: "#{url}submit" )
                    end.to raise_error described_class::Error::MissingSource
                end
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
        it 'parses an XML document into a hash of inputs' do
            described_class.parse_inputs( source ).should == {
                'bookstore > book:nth-of-type(1) > title > text()' => 'Everyday Italian',
                'bookstore > book:nth-of-type(1) > title > @lang' => 'en',
                'bookstore > book:nth-of-type(1) > author > text()' => 'Giada De Laurentiis',
                'bookstore > book:nth-of-type(1) > year > text()' => '2005',
                'bookstore > book:nth-of-type(1) > price > text()' => '30.00',
                'bookstore > book:nth-of-type(1) > @category' => 'COOKING',
                'bookstore > book:nth-of-type(2) > title > text()' => 'Harry Potter',
                'bookstore > book:nth-of-type(2) > title > @lang' => 'en',
                'bookstore > book:nth-of-type(2) > author > text()' => 'J K. Rowling',
                'bookstore > book:nth-of-type(2) > year > text()' => '2005',
                'bookstore > book:nth-of-type(2) > price > text()' => '29.99',
                'bookstore > book:nth-of-type(2) > @category' => 'CHILDREN',
                'bookstore > book:nth-of-type(3) > title > text()' => 'XQuery Kick Start',
                'bookstore > book:nth-of-type(3) > title > @lang' => 'en',
                'bookstore > book:nth-of-type(3) > author:nth-of-type(1) > text()' => 'James McGovern',
                'bookstore > book:nth-of-type(3) > author:nth-of-type(2) > text()' => 'Per Bothner',
                'bookstore > book:nth-of-type(3) > author:nth-of-type(3) > text()' => 'Kurt Cagle',
                'bookstore > book:nth-of-type(3) > author:nth-of-type(4) > text()' => 'James Linn',
                'bookstore > book:nth-of-type(3) > author:nth-of-type(5) > text()' => 'Vaidyanathan Nagarajan',
                'bookstore > book:nth-of-type(3) > year > text()' => '2003',
                'bookstore > book:nth-of-type(3) > price > text()' => '49.99',
                'bookstore > book:nth-of-type(3) > @category' => 'WEB',
                'bookstore > book:nth-of-type(4) > title > text()' => 'Learning XML',
                'bookstore > book:nth-of-type(4) > title > @lang' => 'en',
                'bookstore > book:nth-of-type(4) > author > text()' => 'Erik T. Ray',
                'bookstore > book:nth-of-type(4) > year > text()' => '2003',
                'bookstore > book:nth-of-type(4) > price > text()' => '39.95',
                'bookstore > book:nth-of-type(4) > @category' => 'WEB'
            }
        end
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
