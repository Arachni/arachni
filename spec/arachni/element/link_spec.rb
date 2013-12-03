require 'spec_helper'

describe Arachni::Element::Link do
    it_should_behave_like 'refreshable'
    it_should_behave_like 'auditable', url: web_server_url_for( :link )

    before( :all ) do
        @url = web_server_url_for( :link )
        Arachni::Options.instance.url = @url
        @url = Arachni::Options.instance.url

        @inputs = { 'param_name' => 'param_value' }
        @link = Arachni::Element::Link.new( url: @url, inputs: @inputs )
    end

    it 'is assigned to Arachni::Link for easy access' do
        Arachni::Link.should == Arachni::Element::Link
    end

    describe '#new' do
        context 'when only a url is provided' do
            it 'is used for both the owner #url and #action and be parsed in order to extract #auditable inputs' do
                url = 'http://test.com/?one=2&three=4'
                e = Arachni::Element::Link.new( url: url )
                e.url.should == url
                e.action.should == url
                e.inputs.should == { 'one' => '2', 'three' => '4' }
            end
        end
        context 'when the raw option is a string' do
            it 'is treated as an #action URL and parsed in order to extract #auditable inputs' do
                url    = 'http://test.com/test'
                action = '?one=2&three=4'
                e = Arachni::Element::Link.new( url: url, action: action )
                e.url.should == url
                e.action.should == url + action
                e.inputs.should == { 'one' => '2', 'three' => '4' }
            end
        end
    end

    describe '#id' do
        context 'when the action it contains path parameters' do
            it 'ignores them' do
                e = Arachni::Element::Link.new( url: 'http://test.com/path;p=v?p1=v1&p2=v2', inputs: @inputs )
                c = Arachni::Element::Link.new( url: 'http://test.com/path?p1=v1&p2=v2', inputs: @inputs )
                e.id.should == c.id
            end
        end
    end

    describe '#simple' do
        it 'should return a simplified version as a hash' do
            @link.simple.should == { @link.action => @link.inputs }
        end
    end

    describe '#to_s' do
        it 'should return a URL' do
            url = Arachni::Element::Link.new(
                url:    'http://test.com/test?one=two&amp;three=four',
                inputs: { 'one' => 2, '5' => 'six' }
            ).to_s
            url.should == 'http://test.com/test?one=2&three=four&5=six'
        end
    end

    describe '#type' do
        it 'should be "link"' do
            @link.type.should == :link
        end
    end

    describe '.from_document' do
        context 'when the response does not contain any links' do
            it 'should return an empty array' do
                Arachni::Element::Link.from_document( '', '' ).should be_empty
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

                link = Arachni::Element::Link.from_document( @url, html ).first
                link.action.should == @url + 'test2?param_one=value_one&param_two=value_two'
                link.url.should == @url
                link.inputs.should == {
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

                    link = Arachni::Element::Link.from_document( @url, html ).first
                    link.action.should == base_url + 'test?param_one=value_one&param_two=value_two'
                    link.url.should == @url
                    link.inputs.should == {
                        'param_one'  => 'value_one',
                        'param_two'  => 'value_two'
                    }
                end
            end
        end
    end

    describe '.from_response' do
        it 'returns all available links from an HTTP response' do
            res = Arachni::HTTP::Response.new(
                url: @url + '/?param=val',
                body: '<a href="test?param_one=value_one&param_two=value_two"></a>'
            )
            Arachni::Element::Link.from_response( res ).size.should == 2
        end
    end

    describe '.parse_query_vars' do
        it 'returns the query parameters as a Hash' do
            url = "http://test/?param_one=value_one&param_two=value_two"
            described_class.parse_query_vars( url ).should == {
                'param_one' => 'value_one',
                'param_two' => 'value_two'
            }
        end
        context 'when passed' do
            describe 'nil' do
                it 'returns an empty Hash' do
                    described_class.parse_query_vars( nil ).should == {}
                end
            end
            describe 'an unparsable URL' do
                it 'returns an empty Hash' do
                    url = '$#%^$6#5436#$%^'
                    described_class.parse_query_vars( url ).should == {}
                end
            end
        end
    end

end
