require_relative '../../spec_helper'

describe Arachni::Element::Header do
    it_should_behave_like 'auditable', url: server_url_for( :header ),
                          single_input: true

    before( :all ) do
        @url = server_url_for( :header )

        @inputs = { 'My-header' => 'header_value' }
        @header = Arachni::Element::Header.new( @url, @inputs )
    end

    it 'should be assigned to Arachni::Header for easy access' do
        Arachni::Header.should == Arachni::Element::Header
    end

    describe 'Arachni::Element::HEADER' do
        it 'should return "header"' do
            Arachni::Element::HEADER.should == 'header'
        end
    end

    it 'should retain its assigned inputs' do
        @header.auditable.should == @inputs
    end

    describe '#simple' do
        it 'should return the inputs as is' do
            @header.simple.should == @inputs
        end
    end

    describe '#mutations' do
        describe :param_flip do
            it 'should create a new header' do
                @header.mutations( 'seed', param_flip: true ).last.auditable.keys.should ==
                    %w(seed)
            end
        end
    end

    describe '#type' do
        it 'should be "header"' do
            @header.type.should == 'header'
        end
    end

end
