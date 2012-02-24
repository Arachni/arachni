require_relative '../../../spec_helper'

describe Arachni::Parser::Element::Header do
    before( :all ) do
        @url = server_url_for( :header )

        @inputs = { 'My-header' => 'header_value' }
        @header = Arachni::Parser::Element::Header.new( @url, @inputs )
    end

    it 'should retain its assigned inputs' do
        @header.auditable.should == @inputs
    end

    describe :simple do
        it 'should return the inputs as is' do
            @header.simple.should == @inputs
        end
    end

    describe :submit do
        it 'should perform an appropriate request' do
            body = nil
            @header.submit( remove_id: true ).on_complete {
                |res|
                body = res.body
            }
            run_http!
            body.should == @header.auditable.values.first
        end
    end

    describe :type do
        it 'should be "header"' do
            @header.type.should == 'header'
        end
    end

end
