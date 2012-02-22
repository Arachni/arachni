require_relative '../../../spec_helper'

describe Arachni::Parser::Element::Form do
    before( :all ) do
        @url = server_url_for( :form )

        @raw = {
            'attrs' => {
                'method' => 'post',
                'action' => @url
            },
            'auditable' => [
                {
                    'type'  => 'text',
                    'name'  => 'param_name',
                    'value' => 'param_value'
                }
            ]
        }
        @inputs = { inputs: { 'param_name' => 'param_value' } }
        @form = Arachni::Parser::Element::Form.new( @url, @inputs )

        @http = Arachni::HTTP.instance
    end

    context 'when initialized with out method' do
        it 'should default to "post"' do
            Arachni::Parser::Element::Form.new( @url, @inputs ).method.should == 'post'
        end
    end

    describe :submit do
        context 'when method is post' do
            it 'should perform a POST HTTP request' do
                body_should = @form.method + @form.auditable.to_s
                body = nil

                @form.submit( remove_id: true ).on_complete {
                    |res|
                    body = res.body
                }
                @http.run
                body_should.should == body
            end
        end
        context 'when method is get' do
            it 'should perform a GET HTTP request' do
                f = Arachni::Parser::Element::Form.new( @url, @inputs.merge( method: 'get' ) )
                body_should = f.method + f.auditable.to_s
                body = nil

                f.submit( remove_id: true ).on_complete {
                    |res|
                    body = res.body
                }
                @http.run
                body_should.should == body
            end
        end
    end

    context 'when initialized' do
        context 'with attributes' do
            describe :simple do
                it 'should return a simplified version of form attributes and auditables' do
                    f = Arachni::Parser::Element::Form.new( @url, @raw )
                    f.simple.should == { 'attrs' => @raw['attrs'], 'auditable' => f.auditable }
                end
            end
        end
        context 'with hash key/pair' do
            describe :simple do
                it 'should return a simplified version of form attributes and auditables' do
                    f = Arachni::Parser::Element::Form.new( @url, @inputs )
                    f.simple.should == {
                        'attrs' => {
                            'method' => f.method,
                            'action' => f.action,
                        },
                        'auditable' => f.auditable
                    }
                end
            end
        end
    end

    describe :type do
        it 'should be "form"' do
            @form.type.should == 'form'
        end
    end

end
