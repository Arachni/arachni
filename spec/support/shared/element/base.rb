require 'spec_helper'

shared_examples_for 'element' do
    it_should_behave_like 'with_scope'

    let :normalized_url do
        Arachni::Utilities.normalize_url( 'http://test.com' )
    end
    let(:page) { Factory[:page].dup }

    it "supports #{Arachni::RPC::Serializer}" do
        subject.should == Arachni::RPC::Serializer.deep_clone( subject )
    end

    rpc_attributes = if described_class.ancestors.include? Arachni::Element::Capabilities::Auditable::DOM
                         %w(url)
                     else
                         %w(url initialization_options)
                     end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it "includes 'url'" do
            data['url'].should == subject.url
        end

        if rpc_attributes.include? 'initialization_options'
            it "includes 'initialization_options'" do
                init = subject.initialization_options.dup

                if init.is_a?( Hash )
                    if init[:transition]
                        init[:transition] = init[:transition].to_rpc_data
                    end

                    if init[:template]
                        init[:template] = init[:template].source
                    end

                    if init[:expires]
                        init[:expires] = init[:expires].to_s
                    end

                end

                data['initialization_options'].should == init
            end
        end

        it "includes 'class'" do
            data['class'].should == subject.class.to_s
        end

        it 'excludes #page' do
            data.should_not include 'page'
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        rpc_attributes.each do |attribute|
            it "restores '#{attribute}'" do
                v1 = restored.send( attribute )
                v2 = subject.send( attribute )

                if attribute == 'initialization_options' && v1.is_a?( Hash ) && v1.include?( :expires )
                    v1.delete(:expires).to_s.should == v2.delete(:expires).to_s
                end

                v1.should == v2
            end
        end
    end

    describe '#marshal_dump' do
        it 'excludes #page' do
            subject.page = page
            subject.marshal_dump.should_not include :page
        end
    end

    describe '#url=',
             if: !described_class.ancestors.include?( Arachni::Element::Capabilities::Auditable::DOM ) do
        it 'normalizes the passed URL' do
            url = 'http://test.com/some stuff#frag!'
            subject.url = url
            subject.url.should == Arachni::Utilities.normalize_url( url )
        end
    end

    describe '#page=' do
        it 'sets the associated page' do
            subject.page = page
            subject.page.should == page
        end
    end

    describe '#dup' do
        it 'returns a copy of self' do
            subject.dup.should == subject
        end

        it 'copies #page' do
            subject.page = page
            subject.dup.page.should == page
        end
    end

    describe '#to_h' do
        let(:hash) { subject.to_h }

        it 'includes the #type' do
            hash[:type].should == subject.type
        end

        it 'includes the #url' do
            hash[:url].should == subject.url
        end

        it 'includes the element class as a string' do
            hash[:class].should == described_class.to_s
        end

        it 'is aliased to #to_hash' do
            hash.should == subject.to_hash
        end
    end
end
