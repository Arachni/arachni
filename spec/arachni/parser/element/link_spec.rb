require_relative '../../../spec_helper'

describe Arachni::Parser::Element::Link do
    before( :all ) do
        @url = server_url_for( :link )
        Arachni::Options.instance.url = @url
        @url = Arachni::Options.instance.url

        @inputs = { inputs: { 'param_name' => 'param_value' } }
        @link = Arachni::Parser::Element::Link.new( @url, @inputs )
    end

    describe '#new' do
        context 'when only a url is provided' do
            it 'should be used for both the owner #url and #action and be parsed in order to extract #auditable inputs' do
                url = 'http://test.com/?one=2&three=4'
                e = Arachni::Parser::Element::Link.new( url )
                e.url.should == url
                e.action.should == url
                e.auditable.should == { 'one' => '2', 'three' => '4' }
                e.raw.should == {}
            end
        end
        context 'when the raw option is a string' do
            it 'should be treated as an #action URL and parsed in order to extract #auditable inputs' do
                url    = 'http://test.com/test'
                action = '?one=2&three=4'
                e = Arachni::Parser::Element::Link.new( url, action )
                e.url.should == url
                e.action.should == url + action
                e.auditable.should == { 'one' => '2', 'three' => '4' }
                e.raw.should == { action: e.action, inputs: e.auditable }
            end
        end
        context "when the raw hash option contains a url in 'href', :href, 'action' or :action" do
            it 'should be treated as an #action URL and parsed in order to extract #auditable inputs' do
                ['href', :href, 'action', :action].each do |k|
                    action = '?one=2&three=4'
                    raw    = { k => action }
                    url    = 'http://test.com/test'

                    e = Arachni::Parser::Element::Link.new( url, raw )
                    e.url.should == url
                    e.action.should == url + action
                    e.auditable.should == { 'one' => '2', 'three' => '4' }
                    e.raw.should == raw
                end
            end
        end
        context "when the raw hash option contains a auditable inputs in 'vars', :vars, 'inputs' or :inputs" do
            it 'should be used as auditable inputs' do
                ['vars', :vars, 'inputs', :inputs].each do |k|
                    raw    = { k => { 'one' => '2', 'three' => '4' } }
                    url    = 'http://test.com/test'

                    e = Arachni::Parser::Element::Link.new( url, raw )
                    e.url.should == url
                    e.action.should == url
                    e.auditable.should == { 'one' => '2', 'three' => '4' }
                    e.raw.should == raw
                end
            end
        end
        context "when the raw hash option contains a auditable inputs in :action and :inputs" do
            it 'should be treated as an #action URL and #auditable inputs respectively' do
                url    = 'http://test.com/test/'
                action = 'some/path'
                raw = {
                    :action => action,
                    :inputs => { 'one' => '2', 'three' => '4' }
                }

                e = Arachni::Parser::Element::Link.new( url, raw )
                e.url.should == url
                e.action.should == url + action
                e.auditable.should == { 'one' => '2', 'three' => '4' }
                e.raw.should == raw
            end
        end
        context "when the raw hash option contains a auditable inputs in :action and :inputs" do
            it 'should be treated as an #action URL and #auditable inputs respectively' do
                url = 'http://test.com/test/'
                raw = { 'one' => '2', 'three' => '4' }

                e = Arachni::Parser::Element::Link.new( url, raw )
                e.url.should == url
                e.action.should == url
                e.auditable.should == { 'one' => '2', 'three' => '4' }
                e.raw.should == raw
            end
        end
    end

    describe '#id' do
        context 'when the action it contains path parameters' do
            it 'should ignore them' do
                e = Arachni::Parser::Element::Link.new( 'http://test.com/path;p=v?p1=v1&p2=v2', @inputs[:inputs] )
                c = Arachni::Parser::Element::Link.new( 'http://test.com/path?p1=v1&p2=v2', @inputs[:inputs] )
                e.id.should == c.id
            end
        end
    end

    describe '#submit' do
        it 'should perform a GET HTTP request' do
            body = nil
            @link.submit( remove_id: true ) { |res| body = res.body }
            run_http
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

    describe '#to_s' do
        it 'should return a URL' do
            url = Arachni::Parser::Element::Link.new(
                'http://test.com/test?one=two&amp;three=four',
                { 'one' => 2, '5' => 'six' }
            ).to_s
            url.should == 'http://test.com/test?one=2&three=four&5=six'
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

    describe '.from_response' do
        it 'should return all available links from an HTTP response' do
            res = Typhoeus::Response.new(
                effective_url: @url + '/?param=val',
                body: '<a href="test?param_one=value_one&param_two=value_two"></a>'
            )
            Arachni::Parser::Element::Link.from_response( res ).size.should == 2
        end
    end

end
