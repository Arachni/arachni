require_relative '../../../spec_helper'

describe Arachni::Parser::Element::Link do
    before( :all ) do
        @url = server_url_for( :link )
        Arachni::Options.instance.url = @url
        @url = Arachni::Options.instance.url

        @inputs = { inputs: { 'param_name' => 'param_value' } }
        @link = Arachni::Parser::Element::Link.new( @url, @inputs )
    end

    describe '#submit' do
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

    describe '#auditable' do
        it 'should return the provided inputs' do
            @link.auditable.should == @inputs[:inputs]
        end
    end

    describe '#simple' do
        it 'should return a simplified version as a hash' do
            @link.simple.should == { @link.action => @link.auditable }
        end
    end

    describe '#type' do
        it 'should be "link"' do
            @link.type.should == 'link'
        end
    end

    describe '.from_document' do
        context 'when the response does not contain any links' do
            it 'should return an empty array' do
                Arachni::Parser::Element::Link.from_document( '', '' ).should be_empty
            end
        end
        context 'when the response contains links' do
            it 'should return an array of links' do
                html = '
                <html>
                    <body>
                        <a href="' + @url + '/test2?param_one=value_one&param_two=value_two"></a>
                    </body>
                </html>'

                link = Arachni::Parser::Element::Link.from_document( @url, html ).first
                link.action.should == @url + 'test2?param_one=value_one&param_two=value_two'
                link.url.should == @url
                link.auditable.should == {
                    'param_one'  => 'value_one',
                    'param_two'  => 'value_two'
                }
            end
            context 'and includes a base attribute' do
                it 'should return an array of links with adjusted URIs' do
                    base_url = "#{@url}this_is_the_base/"
                    html = '
                    <html>
                        <head>
                            <base href="' + base_url + '" />
                        </head>
                        <body>
                            <a href="test?param_one=value_one&param_two=value_two"></a>
                        </body>
                    </html>'

                    link = Arachni::Parser::Element::Link.from_document( @url, html ).first
                    link.action.should == base_url + 'test?param_one=value_one&param_two=value_two'
                    link.url.should == @url
                    link.auditable.should == {
                        'param_one'  => 'value_one',
                        'param_two'  => 'value_two'
                    }
                end
            end
        end
    end

end
