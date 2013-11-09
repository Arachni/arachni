require 'spec_helper'

describe Arachni::Element::Form do
    it_should_behave_like 'refreshable'
    it_should_behave_like 'auditable', url: web_server_url_for( :form )

    before( :all ) do
        @utils = Arachni::Module::Utilities
        @url = @utils.normalize_url( web_server_url_for( :form ) )

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
        @form = Arachni::Element::Form.new( @url, @inputs )

        @http = Arachni::HTTP.instance
    end

    it 'assigned to Arachni::Form for easy access' do
        Arachni::Form.should == Arachni::Element::Form
    end

    describe 'Arachni::Element::FORM' do
        it 'returns "form"' do
            Arachni::Element::FORM.should == 'form'
        end
    end

    describe '#new' do
        context 'when passed opts without a method' do
            it 'defaults to "get"' do
                Arachni::Element::Form.new( @url, @inputs ).method.should == 'get'
            end
        end
        context 'when passed opts without an action URL' do
            it 'defaults to the owner URL' do
                Arachni::Element::Form.new( @url ).action.should == @url
            end
        end
        context 'when passed opts without auditable inputs or any other expected option' do
            it 'uses the contents of the opts hash as auditable inputs' do
                e = Arachni::Element::Form.new( @url, @inputs[:inputs] )
                e.auditable.should == @inputs[:inputs]
            end
        end
    end

    describe '#id' do
        context 'when the action it contains path parameters' do
            it 'ignores them' do
                e = Arachni::Element::Form.new( 'http://test.com/path;p=v?p1=v1&p2=v2', @inputs[:inputs] )
                c = Arachni::Element::Form.new( 'http://test.com/path?p1=v1&p2=v2', @inputs[:inputs] )
                e.id.should == c.id
            end
        end
    end

    describe '#field_type_for' do
        it 'returns a field\'s type' do
            e = Arachni::Element::Form.new( 'http://test.com',
                'auditable' => [
                    {
                        'type' => 'password',
                        'name' => 'my_pass'
                    },
                    {
                        'type' => 'hidden',
                        'name' => 'hidden_field'
                    }
                ]
            )

            e.field_type_for( 'my_pass' ).should == 'password'
            e.field_type_for( 'hidden_field' ).should == 'hidden'
        end
    end

    describe '#node' do
        it 'returns the original Nokogiri node' do
            html = '
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <input type=password name="my_first_input" value="my_first_value"" />
                                <input type=radio name="my_second_input" value="my_second_value"" />
                            </form>

                        </body>
                    </html>'

            node = Arachni::Element::Form.from_document( @url, html ).first.node
            node.is_a?( Nokogiri::XML::Element ).should be_true
            node.css( 'input' ).first['name'].should == 'my_first_input'
        end
    end

    describe '#to_html' do
        context 'when there is a node' do
            it 'returns the original form as HTML' do
                html = '
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <input type=password name="my_first_input" value="my_first_value"" />
                                <input type=radio name="my_second_input" value="my_second_value"" />
                            </form>

                        </body>
                    </html>'

                f1 = Arachni::Element::Form.from_document( @url, html ).first
                f2 = Arachni::Element::Form.from_document( @url, f1.to_html ).first
                f2.should == f1
            end
        end

        context 'when there is no node' do
            it 'returns nil' do
                Arachni::Element::Form.new( @url, @inputs[:inputs] ).to_html.should be_nil
            end
        end
    end

    describe '#requires_password?' do
        context 'when the form has a password field' do
            it 'returns true' do
                html = '
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <input type=password name="my_first_input" value="my_first_value"" />
                                <input type=radio name="my_second_input" value="my_second_value"" />
                            </form>

                        </body>
                    </html>'

                Arachni::Element::Form.from_document( @url, html ).
                    first.requires_password?.should be_true
            end
        end
        context 'when the form does not have a password field' do
            it 'returns false' do
                html = '
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <input type=radio name="my_second_input" value="my_second_value"" />
                            </form>

                        </body>
                    </html>'

                Arachni::Element::Form.from_document( @url, html ).
                    first.requires_password?.should be_false
            end
        end
    end

    describe '#original?' do
        context 'when the mutation' do
            context 'is same as the original element' do
                it 'returns true' do
                    inputs = { inputs: { 'param_name' => 'param_value', 'stuff' => nil } }
                    e = Arachni::Element::Form.new( 'http://test.com', inputs )

                    has_original ||= false
                    has_sample   ||= false

                    e.mutations( 'seed' ).each do |m|
                        m.url.should == e.url
                        m.action.should == e.action

                        if m.original?
                            m.altered.should == Arachni::Element::Form::ORIGINAL_VALUES
                            m.auditable.should == e.auditable
                            has_original ||= true
                        end
                    end

                    has_original.should be_true
                end
            end
        end
    end

    describe '#sample?' do
        context 'when the mutation' do
            context 'has been filled-in with sample values' do
                it 'returns true' do
                    inputs = { inputs: { 'param_name' => 'param_value', 'stuff' => nil } }
                    e = Arachni::Element::Form.new( 'http://test.com', inputs )

                    has_original ||= false
                    has_sample   ||= false

                    e.mutations( 'seed' ).each do |m|
                        m.url.should == e.url
                        m.action.should == e.action

                        if m.sample?
                            m.altered.should == Arachni::Element::Form::SAMPLE_VALUES
                            m.auditable.should == Arachni::Module::KeyFiller.fill( e.auditable )
                            has_sample ||= true
                        end
                    end

                    has_sample.should be_true
                end
            end
        end
    end

    describe '#mutations' do
        it 'fuzzes #auditable inputs' do
            inputs = { inputs: { 'param_name' => 'param_value', 'stuff' => nil } }
            e = Arachni::Element::Form.new( 'http://test.com', inputs )

            checked = false
            e.mutations( 'seed' ).each do |m|
                next if m.original? || m.sample?

                m.url.should == e.url
                m.action.should == e.action

                m.auditable.should_not == e.auditable
                checked = true
            end

            checked.should be_true
        end

        it 'sets #altered to the name of the fuzzed input' do
            inputs = { inputs: { 'param_name' => 'param_value', 'stuff' => nil } }
            e = Arachni::Element::Form.new( 'http://test.com', inputs )

            checked = false
            e.mutations( 'seed' ).each do |m|
                next if m.original? || m.sample?

                m.url.should == e.url
                m.action.should == e.action

                m.altered.should_not == e.altered
                m.auditable[m.altered].should include 'seed'

                checked = true
            end

            checked.should be_true
        end

        context 'when it contains more than 1 password field' do
            it 'includes mutations which have the same values for all of them' do
                form = <<-EOHTML
                    <form>
                        <input type="password" name="my_pass" />
                        <input type="password" name="my_pass_validation" />
                    </form>
                EOHTML

                e = Arachni::Element::Form.from_document( 'http://test.com', form ).first

                e.mutations( 'seed' ).reject do |m|
                    m.auditable['my_pass'] != m.auditable['my_pass_validation']
                end.size.should == 6
            end
        end

        describe :skip_orig do
            it 'does not add mutations with original nor default values' do
                e = Arachni::Element::Form.new( 'http://test.com', @inputs )
                mutations = e.mutations( @seed, skip_orig: true )
                mutations.size.should == 4
                mutations.reject { |m| m.mutated? }.size.should == 0
            end
        end
    end

    describe '#nonce_name=' do
        it 'sets the name of the input holding the nonce' do
            f = Arachni::Element::Form.new( @url, nonce: 'value' )
            f.nonce_name = 'nonce'
            f.nonce_name.should == 'nonce'
        end

        context 'when there is no input called nonce_name' do
            it 'raises Arachni::Element::Form::Error::FieldNotFound' do
                trigger = proc do
                    Arachni::Element::Form.new( @url, name: 'value' ).
                        nonce_name = 'stuff'
                end

                expect { trigger.call }.to raise_error Arachni::Error
                expect { trigger.call }.to raise_error Arachni::Element::Form::Error
                expect { trigger.call }.to raise_error Arachni::Element::Form::Error::FieldNotFound
            end
        end
    end

    describe '#has_nonce?' do
        context 'when the form has a nonce' do
            it 'returns true' do
                f = Arachni::Element::Form.new( @url, nonce: 'value' )
                f.nonce_name = 'nonce'
                f.has_nonce?.should be_true
            end
        end
        context 'when the form does not have a nonce' do
            it 'returns false' do
                f = Arachni::Element::Form.new( @url, nonce: 'value' )
                f.has_nonce?.should be_false
            end
        end
    end

    describe '#submit' do
        context 'when method is post' do
            it 'performs a POST HTTP request' do
                body_should = @form.method + @form.auditable.to_s
                body = nil

                @form.submit( remove_id: true ) { |res| body = res.body }
                @http.run
                body_should.should == body
            end
        end
        context 'when method is get' do
            it 'performs a GET HTTP request' do
                f = Arachni::Element::Form.new( @url, @inputs.merge( method: 'get' ) )
                body_should = f.method + f.auditable.to_s
                body = nil

                f.submit( remove_id: true ).on_complete { |res| body = res.body }
                @http.run
                body_should.should == body
            end
        end
        context 'when the form has a nonce' do
            it 'refreshes its value before submitting it' do
                f = Arachni::Element::Form.new( @url + 'with_nonce',
                    @inputs.merge( method: 'get', action: @url + 'get_nonce') )

                f.update 'nonce' => rand( 999 )
                f.nonce_name = 'nonce'

                body_should = f.method + f.auditable.to_s
                body = nil

                f.submit { |res| body = res.body }
                @http.run
                body.should_not == f.auditable['nonce']
                body.to_i.should > 0
            end
        end

    end

    context 'when initialized' do
        context 'with attributes' do
            describe '#simple' do
                it 'returns a simplified version of form attributes and auditables' do
                    f = Arachni::Element::Form.new( @url, @raw )
                    f.simple.should == { 'attrs' => @raw['attrs'], 'auditable' => f.auditable }
                end
            end
        end
        context 'with hash key/pair' do
            describe '#simple' do
                it 'returns a simplified version of form attributes and auditables' do
                    f = Arachni::Element::Form.new( @url, @inputs )
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

    describe '#type' do
        it 'is "form"' do
            @form.type.should == 'form'
        end
    end

    describe '.from_document' do
        context 'when the response does not contain any forms' do
            it 'returns an empty array' do
                Arachni::Element::Form.from_document( '', '' ).should be_empty
            end
        end
        context 'when the response contains forms' do
            context 'with text inputs' do
                it 'returns an array of forms' do
                    html = '
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <input name="my_first_input" value="my_first_value" />
                                <input name="my_second_input" value="my_second_value" />
                            </form>

                        </body>
                    </html>'

                    form = Arachni::Element::Form.from_document( @url, html ).first
                    form.action.should == @utils.normalize_url( @url + '/form_action' )
                    form.name.should == 'my_form'
                    form.url.should == @url
                    form.method.should == 'get'
                    form.auditable.should == {
                        'my_first_input'  => 'my_first_value',
                        'my_second_input' => 'my_second_value'
                    }
                end
            end

            context 'with checkbox inputs' do
                it 'returns an array of forms' do
                    html = '
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <input type="checkbox" name="vehicle" value="Bike">
                                <input type="checkbox" name="stuff" value="Car">
                            </form>

                        </body>
                    </html>'

                    form = Arachni::Element::Form.from_document( @url, html ).first
                    form.action.should == @utils.normalize_url( @url + '/form_action' )
                    form.name.should == 'my_form'
                    form.url.should == @url
                    form.method.should == 'get'
                    form.auditable.should == {
                        'vehicle'  => 'Bike',
                        'stuff' => 'Car'
                    }
                end
            end

            context 'with radio inputs' do
                it 'returns an array of forms' do
                    html = '
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <input type=radio name="my_first_input" value="my_first_value"" />
                                <input type=radio name="my_second_input" value="my_second_value"" />
                            </form>

                        </body>
                    </html>'

                    form = Arachni::Element::Form.from_document( @url, html ).first
                    form.action.should == @utils.normalize_url( @url + '/form_action' )
                    form.name.should == 'my_form'
                    form.url.should == @url
                    form.method.should == 'get'
                    form.auditable.should == {
                        'my_first_input'  => 'my_first_value',
                        'my_second_input' => 'my_second_value'
                    }
                end
            end

            context 'with selects' do
                context 'with values' do
                    it 'returns an array of forms' do
                        html = '
                        <html>
                            <body>
                                <form method="get" action="form_action" name="my_form">
                                    <select name="manufacturer">
                                        <option value="volvo">Volvo</option>
                                        <option value="saab">Saab</option>
                                        <option value="mercedes">Mercedes</option>
                                        <option value="audi">Audi</option>
                                    </select>
                                    <select name="numbers">
                                        <option value="1">1</option>
                                        <option value="2">2</option>
                                    </select>
                                </form>

                            </body>
                        </html>'

                        form = Arachni::Element::Form.from_document( @url, html ).first
                        form.action.should == @utils.normalize_url( @url + '/form_action' )
                        form.name.should == 'my_form'
                        form.url.should == @url
                        form.method.should == 'get'
                        form.auditable.should == {
                            'manufacturer'  => 'volvo',
                            'numbers'       => '1'
                        }
                    end
                end

                context 'without values' do
                    it 'uses the element texts' do
                        html = '
                        <html>
                            <body>
                                <form method="get" action="form_action" name="my_form">
                                    <select name="manufacturer">
                                        <option>Volvo</option>
                                        <option>Saab</option>
                                    </select>
                                    <select name="numbers">
                                        <option>One</option>
                                        <option>Two</option>
                                    </select>
                                </form>

                            </body>
                        </html>'

                        form = Arachni::Element::Form.from_document( @url, html ).first
                        form.action.should == @utils.normalize_url( @url + '/form_action' )
                        form.name.should == 'my_form'
                        form.url.should == @url
                        form.method.should == 'get'
                        form.auditable.should == {
                            'manufacturer'  => 'Volvo',
                            'numbers'       => 'One'
                        }
                    end
                end

                context 'with selected options' do
                    it 'uses their values' do
                        html = '
                        <html>
                            <body>
                                <form method="get" action="form_action" name="my_form">
                                    <select name="manufacturer">
                                        <option>Volvo</option>
                                        <option selected>Saab</option>
                                        <option>Audi</option>
                                    </select>
                                    <select name="numbers">
                                        <option>One</option>
                                        <option selected>Two</option>
                                        <option>Three</option>
                                    </select>
                                </form>

                            </body>
                        </html>'

                        form = Arachni::Element::Form.from_document( @url, html ).first
                        form.action.should == @utils.normalize_url( @url + '/form_action' )
                        form.name.should == 'my_form'
                        form.url.should == @url
                        form.method.should == 'get'
                        form.auditable.should == {
                            'manufacturer'  => 'Saab',
                            'numbers'       => 'Two'
                        }
                    end
                end

                context 'without any options' do
                    it 'uses a nil value' do
                        html = '
                        <html>
                            <body>
                                <form method="get" action="form_action" name="my_form">
                                    <select name="manufacturer">
                                    </select>
                                </form>

                            </body>
                        </html>'

                        form = Arachni::Element::Form.from_document( @url, html ).first
                        form.action.should == @utils.normalize_url( @url + '/form_action' )
                        form.name.should == 'my_form'
                        form.url.should == @url
                        form.method.should == 'get'
                        form.auditable.should == { 'manufacturer' => '' }
                    end
                end


            end

            context 'with a base attribute' do
                it 'respects it and adjust the action accordingly' do
                    base_url = "#{@url}/this_is_the_base/"
                    html = '
                    <html>
                        <head>
                            <base href="' + base_url + '" />
                        </head>
                        <body>
                            <form method="get" action="form_action/is/here?ha=hoo" name="my_form!">
                                <textarea name="text_here" />
                            </form>

                            <form method="post" action="/form_action" name="my_second_form!">
                                <textarea name="text_here" value="my value" />
                            </form>
                        </body>
                    </html>'

                    forms = Arachni::Element::Form.from_document( @url, html )
                    forms.size.should == 2

                    form = forms.shift
                    form.action.should == @utils.normalize_url( base_url + 'form_action/is/here?ha=hoo')
                    form.name.should == 'my_form!'
                    form.url.should == @url
                    form.method.should == 'get'
                    form.auditable.should == { 'text_here' => '' }

                    form = forms.shift
                    form.action.should == @utils.normalize_url( @url + '/form_action' )
                    form.name.should == 'my_second_form!'
                    form.url.should == @url
                    form.method.should == 'post'
                    form.auditable.should == { 'text_here' => "my value" }
                end
            end

            context 'which are not properly closed' do
                it 'sanitizes and return an array of forms' do

                    base_url = "#{@url}/this_is_the_base/"
                    html = '
                    <html>
                        <head>
                            <base href="' + base_url + '" />
                        </head>
                        <body>
                            <form method="get" action="form_2" name="my_form_2">
                                <textarea name="text_here" />

                            <form method="post" action="/form" name="my_form">
                                    <input type="text" name="form_input_1" value="form_val_1">
                                    <input type="text" name="form_input_2" value="form_val_2">
                                    <input type="submit">
                                </p>

                            <form method="get" action="/form_3" name="my_form_3">
                                <input type="text" name="form_3_input_1" value="form_3_val_1">
                                <select name="manufacturer">
                                    <option value="volvo">Volvo</option>
                                    <option value="saab">Saab</option>
                                    <option value="mercedes">Mercedes</option>
                                    <option value="audi">Audi</option>
                                </select>
                        </body>
                    </html>'

                    forms = Arachni::Element::Form.from_document( @url, html )
                    forms.size.should == 3

                    form = forms.shift
                    form.action.should == @utils.normalize_url( base_url + 'form_2' )
                    form.name.should == 'my_form_2'
                    form.url.should == @url
                    form.method.should == 'get'
                    form.auditable.should == { 'text_here' => '' }

                    form = forms.shift
                    form.action.should == @utils.normalize_url( @url + '/form' )
                    form.name.should == 'my_form'
                    form.url.should == @url
                    form.method.should == 'post'
                    form.auditable.should == {
                        'form_input_1' => 'form_val_1',
                        'form_input_2' => 'form_val_2'
                    }

                    form = forms.shift
                    form.action.should == @utils.normalize_url( @url + '/form_3' )
                    form.name.should == 'my_form_3'
                    form.url.should == @url
                    form.method.should == 'get'
                    form.auditable.should == {
                        'form_3_input_1' => 'form_3_val_1',
                        'manufacturer'   => 'volvo'
                    }
                end
            end

        end
    end

    describe '.encode' do
        it 'form-encodes the passed string' do
            Arachni::Element::Form.encode( '% value\ +=&;' ).should == '%25+value%5C+%2B%3D%26%3B'
        end
    end
    describe '#encode' do
        it 'form-encodes the passed string' do
            Arachni::Element::Form.encode( '% value\ +=&;' ).should == '%25+value%5C+%2B%3D%26%3B'
        end
    end

    describe '.decode' do
        it 'form-decodes the passed string' do
            Arachni::Element::Form.decode( '%25+value%5C+%2B%3D%26%3B' ).should == '% value\ +=&;'
        end
    end
    describe '#decode' do
        it 'form-decodes the passed string' do
            Arachni::Element::Form.decode( '%25+value%5C+%2B%3D%26%3B' ).should == '% value\ +=&;'
        end
    end

    describe '.parse_request_body' do
        it 'form-decodes the passed string' do
            Arachni::Element::Form.parse_request_body( 'value%5C+%2B%3D%26%3B=value%5C+%2B%3D%26%3B&testID=53738&deliveryID=53618&testIDs=&deliveryIDs=&selectedRows=2&event=&section=&event%3Dmanage%26amp%3Bsection%3Dexam=Manage+selected+exam' ).should ==
                {
                    "value\\ +=&;" => "value\\ +=&;",
                    "testID" => "53738",
                    "deliveryID" => "53618",
                    "testIDs" => "",
                    "deliveryIDs" => "",
                    "selectedRows" => "2",
                    "event" => "",
                    "section" => "",
                    "event=manage&amp;section=exam" => "Manage selected exam"
                }
        end
    end
    describe '#parse_request_body' do
        it 'form-decodes the passed string' do
            Arachni::Element::Form.parse_request_body( 'value%5C+%2B%3D%26%3B=value%5C+%2B%3D%26%3B&testID=53738&deliveryID=53618&testIDs=&deliveryIDs=&selectedRows=2&event=&section=&event%3Dmanage%26amp%3Bsection%3Dexam=Manage+selected+exam' ).should ==
                {
                    "value\\ +=&;" => "value\\ +=&;",
                    "testID" => "53738",
                    "deliveryID" => "53618",
                    "testIDs" => "",
                    "deliveryIDs" => "",
                    "selectedRows" => "2",
                    "event" => "",
                    "section" => "",
                    "event=manage&amp;section=exam" => "Manage selected exam"
                }
        end
    end

end
