require 'spec_helper'

describe Arachni::Browser::ElementLocator do

    after( :each ) do
        @browser.shutdown if @browser
        @browser = nil
    end

    let(:url) { web_server_url_for( :dom_monitor ) }
    let(:browser) { @browser = Arachni::Browser.new }
    let(:tag_name) { :a }
    let(:attributes) do
        {
            'id'    => 'my-id',
            'class' => 'my-class'
        }
    end
    let(:options) do
        {
            tag_name:   tag_name,
            attributes: attributes
        }
    end
    subject { described_class.new options }

    it "supports #{Arachni::Serializer}" do
        subject.should == Arachni::Serializer.deep_clone( subject )
    end

    describe '.from_html' do
        it 'fills in locator data from HTML code' do
            l = described_class.from_html( '<a href="/test/">Click me</a>' )
            l.tag_name.should == :a
            l.attributes.should == {
                'href' => '/test/'
            }
        end
    end

    describe '.from_node' do
        it 'fills in locator data from a Nokogiri node' do
            l = described_class.from_node(
                Nokogiri::HTML.fragment( '<a href="/test/">Click me</a>' ).children.first
            )
            l.tag_name.should == :a
            l.attributes.should == {
                'href' => '/test/'
            }
        end
    end

    describe '#initialize' do
        describe :tag_name do
            it 'sets #tag_name' do
                described_class.new( tag_name: :a ).tag_name.should == :a
            end

            it 'converts it to a Sybmol' do
                described_class.new( tag_name: 'a' ).tag_name.should == :a
            end
        end

        describe :attributes do
            it 'sets #attributes' do
                described_class.new( attributes: attributes ).attributes.should == attributes
            end
        end
    end

    describe '#locate' do
        it "returns a #{Watir} locator" do
            browser.load "#{url}/digest"

            l = described_class.new( tag_name: :a, attributes: { href: '#stuff'} )
            element = l.locate( browser )
            element.should be_kind_of Watir::Anchor
            element.exists?.should be_true
        end

        context 'when the element cannot be located' do
            it "returns a #{Watir} locator" do
                browser.load "#{url}/digest"
                subject.locate( browser ).exists?.should be_false
            end
        end
    end

    describe '#tag_name=' do
        it 'sets #tag_name' do
            l = described_class.new
            l.tag_name = tag_name
            l.tag_name.should == tag_name
        end

        it 'converts the arguments to a Symbol' do
            l = described_class.new
            l.tag_name = tag_name.to_s
            l.tag_name.should == tag_name.to_sym
        end
    end

    describe '#attributes=' do
        it 'sets #attributes' do
            l = described_class.new
            l.attributes = attributes
            l.attributes.should == attributes
        end

        it 'converts the keys and values to strings' do
            l = described_class.new
            l.attributes = attributes.
                inject({}) { |h, (k,v)| h[k.to_sym] = v.to_sym; h }
            l.attributes.should == attributes
        end

        it 'freezes the keys and values' do
            l = described_class.new
            l.attributes = attributes
            l.attributes.each do |k, v|
                k.should be_frozen
                v.should be_frozen
            end
        end

        it 'freezes the hash' do
            l = described_class.new
            l.attributes = attributes
            l.attributes.should be_frozen
        end
    end

    describe '#locatable_attributes' do
        it 'returns attributes that can be used to locate the element' do
            described_class.new(
                tag_name: :a,
                attributes: attributes.merge(
                    'custom-attr' => 'blah',
                    'data-id' => 'blah'
                )
            ).locatable_attributes.should == { id: 'my-id', data_id: 'blah' }
        end
    end

    describe '#to_s' do
        it 'converts it to an HTML opening tag' do
            subject.to_s.should == '<a id="my-id" class="my-class">'
            described_class.new( tag_name: tag_name ).to_s.should == '<a>'
        end
    end

    describe '#to_hash' do
        it 'converts it to a Hash' do
            subject.to_hash.should == options
        end

        it 'is aliased to #to_h' do
            subject.to_h.should == subject.to_hash
        end
    end

    describe '#dup' do
        it 'duplicates self' do
            subject.dup.should == subject
            subject.dup.object_id.should_not == subject.object_id
        end
    end

    describe '#hash' do
        context 'when the #tag_name changes' do
            it 'changes' do
                hash = subject.hash
                hash.should == subject.hash

                subject.tag_name = 'stuff'
                hash.should_not == subject.hash
            end
        end

        context 'when the #attributes change' do
            it 'changes' do
                hash = subject.hash
                hash.should == subject.hash

                subject.attributes = { 1 => 2 }
                hash.should_not == subject.hash
            end
        end
    end

    describe '#==' do
        context 'when the objects are equal' do
            it 'returns true' do
                subject.should == subject
                subject.dup.should == subject
            end
        end

        context 'when the objects are not equal' do
            it 'returns false' do
                dup = subject.dup
                dup.tag_name = 'stuff'
                dup.should_not == subject
            end
        end
    end
end
