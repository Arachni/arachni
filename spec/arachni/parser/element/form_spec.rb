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

    describe :from_document do
        context 'when the response does not contain any forms' do
            it 'should return an empty array' do
                Arachni::Parser::Element::Form.from_document( '', '' ).should be_empty
            end
        end
        context 'when the response contains forms' do
            context 'with text inputs' do
                it 'should return an array of forms' do
                    html = '
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <input name="my_first_input" value="my_first_value"" />
                                <input name="my_second_input" value="my_second_value"" />
                            </form>

                        </body>
                    </html>'

                    form = Arachni::Parser::Element::Form.from_document( @url, html ).first
                    form.action.should == @url + '/form_action'
                    form.name.should == 'my_form'
                    form.url.should == @url
                    form.method.should == 'get'
                    form.auditable.should == {
                        'my_first_input'  => 'my_first_value',
                        'my_second_input' => 'my_second_value'
                    }
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

                    form = Arachni::Parser::Element::Form.from_document( @url, html ).first
                    form.action.should == @url + '/form_action'
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

                        form = Arachni::Parser::Element::Form.from_document( @url, html ).first
                        form.action.should == @url + '/form_action'
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

                        form = Arachni::Parser::Element::Form.from_document( @url, html ).first
                        form.action.should == @url + '/form_action'
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

                        form = Arachni::Parser::Element::Form.from_document( @url, html ).first
                        form.action.should == @url + '/form_action'
                        form.name.should == 'my_form'
                        form.url.should == @url
                        form.method.should == 'get'
                        form.auditable.should == {
                            'manufacturer'  => 'Saab',
                            'numbers'       => 'Two'
                        }
                    end
                end

            end

            context 'with a base attribute' do
                it 'should respect it and adjust the action accordingly' do
                    base_url = "#{@url}/this_is_the_base"
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

                    forms = Arachni::Parser::Element::Form.from_document( @url, html )
                    forms.size.should == 2

                    form = forms.shift
                    form.action.should == base_url + '/form_action/is/here?ha=hoo'
                    form.name.should == 'my_form!'
                    form.url.should == @url
                    form.method.should == 'get'
                    form.auditable.should == { 'text_here' => nil }

                    form = forms.shift
                    form.action.should == @url + '/form_action'
                    form.name.should == 'my_second_form!'
                    form.url.should == @url
                    form.method.should == 'post'
                    form.auditable.should == { 'text_here' => "my value" }
                end
            end

            context 'which are not properly closed' do
                it 'should sanitize and return an array of forms' do

                    base_url = "#{@url}/this_is_the_base"
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

                    forms = Arachni::Parser::Element::Form.from_document( @url, html )
                    forms.size.should == 3

                    form = forms.shift
                    form.action.should == base_url + '/form_2'
                    form.name.should == 'my_form_2'
                    form.url.should == @url
                    form.method.should == 'get'
                    form.auditable.should == { 'text_here' => nil }

                    form = forms.shift
                    form.action.should == @url + '/form'
                    form.name.should == 'my_form'
                    form.url.should == @url
                    form.method.should == 'post'
                    form.auditable.should == {
                        'form_input_1' => 'form_val_1',
                        'form_input_2' => 'form_val_2'
                    }

                    form = forms.shift
                    form.action.should == @url + '/form_3'
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

end
