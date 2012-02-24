require_relative '../../../spec_helper'

describe Arachni::Parser::Element::Link do
    before( :all ) do
        @url = server_url_for( :link )

        @inputs = { inputs: { 'param_name' => 'param_value' } }
        @link = Arachni::Parser::Element::Link.new( @url, @inputs )
    end

    describe :submit do
        it 'should perform a GET HTTP request' do
            body = nil
            @link.submit( remove_id: true ).on_complete {
                |res|
                body = res.body
            }
            run_http!
            @link.auditable.to_s.should == body
        end
    end

    describe :auditable do
        it 'should return the provided inputs' do
            @link.auditable.should == @inputs[:inputs]
        end
    end

    describe :simple do
        it 'should return a simplified version as a hash' do
            @link.simple.should == { @link.action => @link.auditable }
        end
    end

    describe :type do
        it 'should be "link"' do
            @link.type.should == 'link'
        end
    end

end
