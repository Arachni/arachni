require 'spec_helper'

describe Arachni::Element::Header do
    it_should_behave_like 'auditable', url: web_server_url_for( :header ),
                          single_input: true, supports_nulls: false

    before( :all ) do
        @url = web_server_url_for( :header )

        @inputs = { 'My-header' => 'header_value' }
        @header = Arachni::Element::Header.new( @url, @inputs )
    end

    it 'is be assigned to Arachni::Header for easy access' do
        Arachni::Header.should == Arachni::Element::Header
    end

    describe 'Arachni::Element::HEADER' do
        it 'returns "header"' do
            Arachni::Element::HEADER.should == 'header'
        end
    end

    it 'retains its assigned inputs' do
        @header.auditable.should == @inputs
    end

    describe '#simple' do
        it 'returns the inputs as is' do
            @header.simple.should == @inputs
        end
    end

    describe '#mutations' do
        describe :param_flip do
            it 'creates a new header' do
                @header.mutations( 'seed', param_flip: true ).last.
                    auditable.keys.should == %w(seed)
            end
        end

        describe :format do
            it 'does not include NULLs' do
                @header.mutations( 'seed' ).
                    select { |m| m.altered_value.include? "\0" }.should be_empty
            end
        end
    end

    describe '#name' do
        it 'returns the header name' do
            @header.name.should == 'My-header'
        end
    end

    describe '#value' do
        it 'returns the header value' do
            @header.value.should == 'header_value'
        end
    end

    describe '#type' do
        it 'is "header"' do
            @header.type.should == 'header'
        end
    end

end
