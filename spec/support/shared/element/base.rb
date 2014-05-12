require 'spec_helper'

shared_examples_for 'element' do
    let( :normalized_url ) do
        Arachni::Utilities.normalize_url( 'http://test.com' )
    end

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
                init[:transition] = init[:transition].to_rpc_data if init[:transition]

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
                restored.send( attribute ).should == subject.send( attribute )
            end
        end
    end

    describe '#marshal_dump' do
        it 'excludes #page' do
            subject.page = Factory[:page]
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
            subject.page = Factory[:page]
            subject.page.should == Factory[:page]
        end
    end

    describe '#dup' do
        it 'returns a copy of self' do
            subject.dup.should == subject
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
