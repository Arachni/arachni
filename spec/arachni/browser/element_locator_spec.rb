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

    it "supports #{Arachni::RPC::Serializer}" do
        expect(subject).to eq(Arachni::RPC::Serializer.deep_clone( subject ))
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        %w(tag_name attributes).each do |attribute|
            it "includes '#{attribute}'" do
                expect(data[attribute]).to eq(subject.send( attribute ))
            end
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        %w(tag_name attributes).each do |attribute|
            it "restores '#{attribute}'" do
                expect(restored.send( attribute )).to eq(subject.send( attribute ))
            end
        end
    end

    describe '.from_html' do
        it 'fills in locator data from HTML code' do
            l = described_class.from_html( '<a href="/test/">Click me</a>' )
            expect(l.tag_name).to eq(:a)
            expect(l.attributes).to eq({
                'href' => '/test/'
            })
        end
    end

    describe '.from_node' do
        it 'fills in locator data from a Nokogiri node' do
            l = described_class.from_node(
                Nokogiri::HTML.fragment( '<a href="/test/">Click me</a>' ).children.first
            )
            expect(l.tag_name).to eq(:a)
            expect(l.attributes).to eq({
                'href' => '/test/'
            })
        end
    end

    describe '#initialize' do
        describe ':tag_name' do
            it 'sets #tag_name' do
                expect(described_class.new( tag_name: :a ).tag_name).to eq(:a)
            end

            it 'converts it to a Symbol' do
                expect(described_class.new( tag_name: 'a' ).tag_name).to eq(:a)
            end
        end

        describe ':attributes' do
            it 'sets #attributes' do
                expect(described_class.new( attributes: attributes ).attributes).to eq(attributes)
            end
        end
    end

    describe '#locate' do
        it "returns a #{Selenium::WebDriver::Element} locator" do
            browser.load "#{url}/digest"

            l = described_class.new( tag_name: :a, attributes: { href: '#stuff'} )
            element = l.locate( browser )
            expect(element).to be_kind_of Selenium::WebDriver::Element
        end

        context 'when the element cannot be located' do
            it "raises #{Selenium::WebDriver::Error::NoSuchElementError}" do
                browser.load "#{url}/digest"

                expect do
                    subject.locate( browser )
                end.to raise_error Selenium::WebDriver::Error::NoSuchElementError
            end
        end
    end

    describe '#css' do
        context 'when there are no attributes' do
            it 'returns a CSS locator with just the tag name' do
                expect(described_class.new( tag_name: :a ).css).to eq('a')
            end
        end

        context 'when there is an attribute' do
            it 'returns a CSS locator with the attribute' do
                expect(described_class.new(
                    tag_name: :a,
                    attributes: {
                        stuff: 'blah'
                    }
                ).css).to eq('a[stuff="blah"]')
            end

            context 'with values that include double quotes' do
                it 'escapes them' do
                    expect(described_class.new(
                        tag_name: :a,
                        attributes: {
                            stuff: 'bl"ah'
                        }
                    ).css).to eq('a[stuff="bl\"ah"]')
                end
            end
        end

        context 'when there are multiple attributes' do
            it 'returns a CSS locator with the attributes' do
                expect(described_class.new(
                    tag_name: :a,
                    attributes: {
                        stuff:  'blah',
                        stuff2: 'blah2'
                    }
                ).css).to eq('a[stuff="blah"][stuff2="blah2"]')
            end

            context 'and an ID' do
                it 'only includes the ID' do
                    expect(described_class.new(
                        tag_name: :a,
                        attributes: {
                            stuff:  'blah',
                            stuff2: 'blah2',
                            id:     'my-id'
                        }
                    ).css).to eq('a[id="my-id"]')
                end
            end

            context "and a #{described_class::ARACHNI_ID}" do
                it "only includes the #{described_class::ARACHNI_ID}" do
                    expect(described_class.new(
                       tag_name: :a,
                       attributes: {
                           stuff:  'blah',
                           stuff2: 'blah2',
                           described_class::ARACHNI_ID =>     'my-id'
                       }
                   ).css).to eq("a[#{described_class::ARACHNI_ID}=\"my-id\"]")
                end
            end

            context 'and includes data ones' do
                it 'excludes them' do
                    expect(described_class.new(
                        tag_name: :a,
                        attributes: {
                            'data-stuff'  => 'blah',
                            'data-stuff2' => 'blah2',
                            'class'       => 'blah3'
                        }
                    ).css).to eq('a[class="blah3"]')
                end
            end
        end
    end

    describe '#tag_name=' do
        it 'sets #tag_name' do
            l = described_class.new
            l.tag_name = tag_name
            expect(l.tag_name).to eq(tag_name)
        end

        it 'converts the arguments to a Symbol' do
            l = described_class.new
            l.tag_name = tag_name.to_s
            expect(l.tag_name).to eq(tag_name.to_sym)
        end
    end

    describe '#attributes=' do
        it 'sets #attributes' do
            l = described_class.new
            l.attributes = attributes
            expect(l.attributes).to eq(attributes)
        end

        it 'converts the keys and values to strings' do
            l = described_class.new
            l.attributes = attributes.
                inject({}) { |h, (k,v)| h[k.to_sym] = v.to_sym; h }
            expect(l.attributes).to eq(attributes)
        end

        it 'freezes the keys and values' do
            l = described_class.new
            l.attributes = attributes
            l.attributes.each do |k, v|
                expect(k).to be_frozen
                expect(v).to be_frozen
            end
        end

        it 'freezes the hash' do
            l = described_class.new
            l.attributes = attributes
            expect(l.attributes).to be_frozen
        end
    end

    describe '#locatable_attributes' do
        it 'returns attributes that can be used to locate the element' do
            expect(described_class.new(
                tag_name: :a,
                attributes: attributes.merge(
                    'custom-attr' => 'blah',
                    'data-id' => 'blah'
                )
            ).locatable_attributes).to eq({ id: 'my-id', data_id: 'blah' })
        end
    end

    describe '#to_s' do
        it 'converts it to an HTML opening tag' do
            expect(subject.to_s).to eq('<a id="my-id" class="my-class">')
            expect(described_class.new( tag_name: tag_name ).to_s).to eq('<a>')
        end
    end

    describe '#inspect' do
        it 'is aliased to #to_s' do
            expect(subject.to_s).to eq(subject.inspect)
        end
    end

    describe '#to_hash' do
        it 'converts it to a Hash' do
            expect(subject.to_hash).to eq(options)
        end

        it 'is aliased to #to_h' do
            expect(subject.to_h).to eq(subject.to_hash)
        end
    end

    describe '#dup' do
        it 'duplicates self' do
            expect(subject.dup).to eq(subject)
            expect(subject.dup.object_id).not_to eq(subject.object_id)
        end
    end

    describe '#hash' do
        context 'when the #tag_name changes' do
            it 'changes' do
                hash = subject.hash
                expect(hash).to eq(subject.hash)

                subject.tag_name = 'stuff'
                expect(hash).not_to eq(subject.hash)
            end
        end

        context 'when the #attributes change' do
            it 'changes' do
                hash = subject.hash
                expect(hash).to eq(subject.hash)

                subject.attributes = { 1 => 2 }
                expect(hash).not_to eq(subject.hash)
            end
        end
    end

    describe '#==' do
        context 'when the objects are equal' do
            it 'returns true' do
                expect(subject).to eq(subject)
                expect(subject.dup).to eq(subject)
            end
        end

        context 'when the objects are not equal' do
            it 'returns false' do
                dup = subject.dup
                dup.tag_name = 'stuff'
                expect(dup).not_to eq(subject)
            end
        end
    end
end
