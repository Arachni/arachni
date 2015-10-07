require 'spec_helper'

shared_examples_for 'element' do
    it_should_behave_like 'with_scope'

    let :normalized_url do
        Arachni::Utilities.normalize_url( 'http://test.com' )
    end
    let(:page) { Factory[:page].dup }

    it "supports #{Arachni::RPC::Serializer}" do
        expect(subject).to eq(Arachni::RPC::Serializer.deep_clone( subject ))
    end

    rpc_attributes = if described_class.ancestors.include? Arachni::Element::DOM
                         %w(url)
                     else
                         %w(url initialization_options)
                     end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it "includes 'url'" do
            expect(data['url']).to eq(subject.url)
        end

        if rpc_attributes.include? 'initialization_options'
            it "includes 'initialization_options'" do
                init = subject.initialization_options.dup

                if init.is_a?( Hash )
                    init = init.my_stringify_keys(false)

                    if init['transition']
                        init['transition'] = init['transition'].to_rpc_data
                    end

                    if init['template']
                        init['template'] = init['template'].source
                    end

                    if init['expires']
                        init['expires'] = init['expires'].to_s
                    end
                end

                expect(data['initialization_options']).to eq(init)
            end
        end

        it "includes 'class'" do
            expect(data['class']).to eq(subject.class.to_s)
        end

        it 'excludes #page' do
            expect(data).not_to include 'page'
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        rpc_attributes.each do |attribute|
            it "restores '#{attribute}'" do
                v1 = restored.send( attribute )
                v2 = subject.send( attribute )

                if attribute == 'initialization_options' && v1.is_a?( Hash )
                    if v1.include? :expires
                        expect(v1.delete(:expires).to_s).to eq(v2.delete(:expires).to_s)
                    end

                    if v1.include? :template
                        expect(v1.delete(:template).source).to eq(v2.delete(:template).source)
                    end
                end

                expect(v1).to eq(v2)
            end
        end
    end

    describe '.too_big?' do
        context 'when passed an Numeric' do
            context "equal to #{described_class::MAX_SIZE}" do
                it 'returns true' do
                    expect(described_class.too_big?( described_class::MAX_SIZE )).to be_truthy
                end
            end

            context "larger than #{described_class::MAX_SIZE}" do
                it 'returns true' do
                    expect(described_class.too_big?( described_class::MAX_SIZE + 1 )).to be_truthy
                end
            end

            context "smaller than #{described_class::MAX_SIZE}" do
                it 'returns false' do
                    expect(described_class.too_big?( described_class::MAX_SIZE - 1 )).to be_falsey
                end
            end
        end

        context 'when passed a String' do
            context "whose size is equal to #{described_class::MAX_SIZE}" do
                it 'returns true' do
                    expect(described_class.too_big?( 'a' * described_class::MAX_SIZE )).to be_truthy
                end
            end

            context "whose size is larger than #{described_class::MAX_SIZE}" do
                it 'returns true' do
                    expect(described_class.too_big?( 'a' * (described_class::MAX_SIZE + 1) )).to be_truthy
                end
            end

            context "whose size is smaller than #{described_class::MAX_SIZE}" do
                it 'returns false' do
                    expect(described_class.too_big?( 'a' * (described_class::MAX_SIZE - 1) )).to be_falsey
                end
            end
        end
    end

    describe '#marshal_dump' do
        it 'excludes #page' do
            subject.page = page
            expect(subject.marshal_dump).not_to include :page
        end
    end

    describe '#url=',
             if: !described_class.ancestors.include?( Arachni::Element::DOM ) do
        it 'normalizes the passed URL' do
            url = 'http://test.com/some stuff#frag!'
            subject.url = url
            expect(subject.url).to eq(Arachni::Utilities.normalize_url( url ))
        end
    end

    describe '#page=' do
        it 'sets the associated page' do
            subject.page = page
            expect(subject.page).to eq(page)
        end
    end

    describe '#dup' do
        it 'returns a copy of self' do
            expect(subject.dup).to eq(subject)
        end

        it 'copies #page' do
            subject.page = page
            expect(subject.dup.page).to eq(page)
        end
    end

    describe '#to_h' do
        let(:hash) { subject.to_h }

        it 'includes the #type' do
            expect(hash[:type]).to eq(subject.type)
        end

        it 'includes the #url' do
            expect(hash[:url]).to eq(subject.url)
        end

        it 'includes the element class as a string' do
            expect(hash[:class]).to eq(described_class.to_s)
        end

        it 'is aliased to #to_hash' do
            expect(hash).to eq(subject.to_hash)
        end
    end
end
