require_relative '../../spec_helper'

describe Arachni::Element::Form do
    it_should_behave_like 'refreshable'
    it_should_behave_like 'auditable', url: server_url_for( :form )

    before( :all ) do
        @utils = Arachni::Module::Utilities
        @url = @utils.normalize_url( server_url_for( :form ) )

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

    it 'should be assigned to Arachni::Form for easy access' do
        Arachni::Form.should == Arachni::Element::Form
    end

    describe 'Arachni::Element::FORM' do
        it 'should return "form"' do
            Arachni::Element::FORM.should == 'form'
        end
    end

    describe '#new' do
        context 'when passed opts without a method' do
            it 'should default to "get"' do
                Arachni::Element::Form.new( @url, @inputs ).method.should == 'get'
            end
        end
        context 'when passed opts without an action URL' do
            it 'should default to the owner URL' do
                Arachni::Element::Form.new( @url ).action.should == @url
            end
        end
        context 'when passed opts without auditable inputs or any other expected option' do
            it 'should use the contents of the opts hash as auditable inputs' do
                e = Arachni::Element::Form.new( @url, @inputs[:inputs] )
                e.auditable.should == @inputs[:inputs]
            end
        end
    end

    describe '#id' do
        context 'when the action it contains path parameters' do
            it 'should ignore them' do
                e = Arachni::Element::Form.new( 'http://test.com/path;p=v?p1=v1&p2=v2', @inputs[:inputs] )
                c = Arachni::Element::Form.new( 'http://test.com/path?p1=v1&p2=v2', @inputs[:inputs] )
                e.id.should == c.id
            end
        end
    end

    describe '#field_type_for' do
        it 'should return a field\'s type' do
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

    describe '#requires_password?' do
        context 'when the form has a password field' do
            it 'should return true' do
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
            it 'should return false' do
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

    describe '#mutations' do
        it 'should only affect #auditable and #altered (unless #original? or #sample?)' do
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

                if m.sample?
                    m.altered.should == Arachni::Element::Form::SAMPLE_VALUES
                    m.auditable.should == Arachni::Module::KeyFiller.fill( e.auditable )
                    has_sample ||= true
                end

                if !m.original? && !m.sample?
                    m.altered.should_not == e.altered
                    m.auditable.should_not == e.auditable
                end
            end

            has_original.should be_true
            has_sample.should be_true
        end

        context 'when it contains more than 1 password field' do
            it 'should include mutations which have the same values for all of them' do
                e = Arachni::Element::Form.new( 'http://test.com',
                    'auditable' => [
                        {
                            'type' => 'password',
                            'name' => 'my_pass'
                        },
                        {
                            'type' => 'password',
                            'name' => 'my_pass_validation'
                        }
                    ]
                )

                e.mutations( 'seed' ).reject do |m|
                    m.auditable['my_pass'] != m.auditable['my_pass_validation']
                end.size.should == 6
            end
        end

        describe :skip_orig do
            it 'should not add mutations with original nor default values' do
                e = Arachni::Element::Form.new( 'http://test.com', @inputs )
                mutations = e.mutations( @seed, skip_orig: true )
                mutations.size.should == 4
                mutations.reject { |m| m.mutated? }.size.should == 0
            end
        end
    end

    describe '#nonce_name=' do
        it 'should set the name of the input holding the nonce' do
            f = Arachni::Element::Form.new( @url, nonce: 'value' )
            f.nonce_name = 'nonce'
            f.nonce_name.should == 'nonce'
        end

        context 'when there is no input called nonce_name' do
            it 'should raise an exception' do
                raised = false
                begin
                    Arachni::Element::Form.new( @url, name: 'value' ).nonce_name = 'stuff'
                rescue
                    raised = true
                end
                raised.should be_true
            end
        end
    end

    describe '#has_nonce?' do
        context 'when the form has a nonce' do
            it 'should return true' do
                f = Arachni::Element::Form.new( @url, nonce: 'value' )
                f.nonce_name = 'nonce'
                f.has_nonce?.should be_true
            end
        end
        context 'when the form does not have a nonce' do
            it 'should return false' do
                f = Arachni::Element::Form.new( @url, nonce: 'value' )
                f.has_nonce?.should be_false
            end
        end
    end

    describe '#submit' do
        context 'when method is post' do
            it 'should perform a POST HTTP request' do
                body_should = @form.method + @form.auditable.to_s
                body = nil

                @form.submit( remove_id: true ) { |res| body = res.body }
                @http.run
                body_should.should == body
            end
        end
        context 'when method is get' do
            it 'should perform a GET HTTP request' do
                f = Arachni::Element::Form.new( @url, @inputs.merge( method: 'get' ) )
                body_should = f.method + f.auditable.to_s
                body = nil

                f.submit( remove_id: true ).on_complete { |res| body = res.body }
                @http.run
                body_should.should == body
            end
        end
        context 'when the form has a nonce' do
            it 'should refresh its value before submitting it' do
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
                it 'should return a simplified version of form attributes and auditables' do
                    f = Arachni::Element::Form.new( @url, @raw )
                    f.simple.should == { 'attrs' => @raw['attrs'], 'auditable' => f.auditable }
                end
            end
        end
        context 'with hash key/pair' do
            describe '#simple' do
                it 'should return a simplified version of form attributes and auditables' do
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
        it 'should be "form"' do
            @form.type.should == 'form'
        end
    end

    describe '.from_document' do
        context 'when the response does not contain any forms' do
            it 'should return an empty array' do
                Arachni::Element::Form.from_document( '', '' ).should be_empty
            end
        end
        context 'when the response contains forms' do
            context 'with text inputs' do
                it 'should return an array of forms' do
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

            context 'when the action match a skip rule' do
                it 'should be ignored' do
                    Arachni::Options.url     = @url
                    Arachni::Options.exclude = 'skip-this'

                    url = "http://test.com/this_is_the_base/"

                    html = <<-HTML
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <input name="my_first_input" value="my_first_value" />
                            </form>

                            <form method="get" action="#{url}" name="my_form">
                                <input name="my_first_input" value="my_first_value" />
                            </form>

                            <form method="get" action="?skip-this" name="my_form">
                                <input name="my_first_input" value="my_first_value" />
                            </form>

                        </body>
                    </html>
                    HTML

                    Arachni::Element::Form.from_document( @url, html ).size.should == 1
                    Arachni::Options.reset
                end
            end

            context 'with radio inputs' do
                it 'should return an array of forms' do
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
                    it 'should return an array of forms' do
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
                    it 'should use the element texts' do
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
                    it 'should use their values' do
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
                    it 'should use a nil value' do
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
                it 'should respect it and adjust the action accordingly' do
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
                it 'should sanitize and return an array of forms' do

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
        it 'should form encode the passed string' do
            Arachni::Element::Form.encode( '% value\ +=&;' ).should == '%25+value%5C+%2B%3D%26%3B'
        end
    end
    describe '#encode' do
        it 'should form encode the passed string' do
            Arachni::Element::Form.encode( '% value\ +=&;' ).should == '%25+value%5C+%2B%3D%26%3B'
        end
    end

    describe '.decode' do
        it 'should form decode the passed string' do
            Arachni::Element::Form.decode( '%25+value%5C+%2B%3D%26%3B' ).should == '% value\ +=&;'
        end
    end
    describe '#decode' do
        it 'should form decode the passed string' do
            Arachni::Element::Form.decode( '%25+value%5C+%2B%3D%26%3B' ).should == '% value\ +=&;'
        end
    end

    describe '.parse_request_body' do
        it 'should form decode the passed string' do
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
        it 'should form decode the passed string' do
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
