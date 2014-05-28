require 'spec_helper'

describe Arachni::Element::Form do
    html = '<form method="get" action="form_action" name="my_form">
                <input type=password name="my_first_input" value="my_first_value"" />
                <input type=radio name="my_second_input" value="my_second_value"" />
            </form>'

    it_should_behave_like 'element'
    it_should_behave_like 'with_node', html
    it_should_behave_like 'with_dom',  html
    it_should_behave_like 'refreshable'
    it_should_behave_like 'auditable'

    def auditable_extract_parameters( resource )
        YAML.load( resource.body )
    end

    def run
        http.run
    end

    subject { described_class.new( options ) }
    let(:url) { utilities.normalize_url( web_server_url_for( :form ) ) }
    let(:http) { Arachni::HTTP::Client }
    let(:utilities) { Arachni::Utilities }
    let(:options) do
        {
            name:   'login-form',
            url:    "#{url}submit",
            inputs: {
                'user'         => 'joe',
                'hidden_field' => 'hidden-value',
                'password'     => 's3cr3t'
            },
            html: html
        }
    end

    it 'assigned to Arachni::Form for easy access' do
        Arachni::Form.should == described_class
    end

    describe '#initialize' do
        describe :method do
            it 'defaults to :get' do
                described_class.new( url: url ).method.should == :get
            end
        end
        describe :name do
            it 'sets #name' do
                described_class.new( url: url, name: 'john' ).name.should == 'john'
            end
        end
        describe :action do
            it 'sets #action' do
                action = "#{url}stuff"
                described_class.new( url: url, action: action ).action.should == action
            end

            context 'when nil' do
                it 'defaults to :url' do
                    described_class.new( url: url ).action.should == url
                end
            end
        end
    end

    describe '#mutation_with_original_values?' do
        it 'returns false' do
            subject.mutation_with_original_values?.should be_false
        end

        context 'when #mutation_with_original_values' do
            it 'returns true' do
                subject.mutation_with_original_values
                subject.mutation_with_original_values?.should be_true
            end
        end
    end

    describe '#mutation_with_sample_values?' do
        it 'returns false' do
            subject.mutation_with_sample_values?.should be_false
        end

        context 'when #mutation_with_sample_values' do
            it 'returns true' do
                subject.mutation_with_sample_values
                subject.mutation_with_sample_values?.should be_true
            end
        end
    end

    describe '#audit_id' do
        context 'when #force_train?' do
            it 'returns #mutation_id' do
                subject.mutation_with_original_values
                subject.audit_id( 'stuff' ).should == subject.id
            end
        end
    end

    describe '#name_or_id' do
        context 'when a #name is available' do
            it 'returns it' do
                described_class.new( url: url, name: 'john' ).
                    name_or_id.should == 'john'
            end
        end

        context 'when a #name is not available' do
            subject { described_class.new( url: url, id: 'john' ) }

            it 'returns the configured :id' do
                subject.name.should be_nil
                subject.name_or_id.should == 'john'
            end
        end

        context 'when no #name nor :id are available' do
            subject { described_class.new( url: url ) }

            it 'returns nil' do
                subject.name_or_id.should be_nil
            end
        end
    end

    describe '#dom' do
        context 'when there are no #inputs' do
            it 'returns nil' do
                subject.inputs = {}
                subject.dom.should be_nil
            end
        end

        context 'when there is no #node' do
            it 'returns nil' do
                subject.html = nil
                subject.dom.should be_nil
            end
        end
    end

    describe '#force_train?' do
        it 'returns false' do
            subject.force_train?.should be_false
        end

        context 'when #mutation_with_original_values?' do
            it 'returns true' do
                subject.mutation_with_original_values
                subject.force_train?.should be_true
            end
        end
        context 'when #mutation_with_sample_values?' do
            it 'returns true' do
                subject.mutation_with_sample_values
                subject.force_train?.should be_true
            end
        end
    end

    describe '#action=' do
        let(:action) { action = "#{url}?stuff=here&and=here2" }
        let(:query_inputs) do
            {
                'stuff' => 'here',
                'and'   => 'here2'
            }
        end
        let(:option_inputs) do
            {
                'more-stuff'     => 'here3',
                'yet-more-stuff' => 'here4'
            }
        end
        subject do
            described_class.new(
                url:    url,
                action: action,
                inputs: option_inputs,
                method: method
            )
        end

        context 'when #method is' do
            describe :get do
                let(:method) { :get }

                it 'removes the URL query' do
                    subject.action.should == url
                end

                it 'merges the URL query parameters with the given :inputs' do
                    subject.inputs.should == query_inputs.merge( option_inputs )
                end

                context 'when URL query parameters and :inputs have the same name' do
                    let(:option_inputs) do
                        {
                            'stuff'          => 'here3',
                            'yet-more-stuff' => 'here4'
                        }
                    end

                    it 'it gives precedence to the :inputs' do
                        subject.inputs.should == query_inputs.merge( option_inputs )
                    end
                end
            end

            describe :post do
                let(:method) { :post }

                it 'preserves the URL query' do
                    subject.action.should == action
                end

                it 'ignores the URL query parameters' do
                    subject.inputs.should == option_inputs
                end
            end
        end
    end

    describe '#details_for' do
        context 'when input details are given during initialization' do
            it 'returns that data ' do
                options = {
                    url:    url,
                    inputs: {
                        'password' => {
                            id:    'my-password',
                            type:  :password,
                            value: 's3cr3t'
                        }
                    }
                }

                described_class.new( options ).details_for( :password ).should ==
                    options[:inputs]['password']
            end
        end
        describe 'when no data is available' do
            it 'return nil' do
                described_class.new( options ).details_for( :username ).should == {}
            end
        end
    end

    describe '#name' do
        context 'when there is a form name' do
            it 'returns it' do
                described_class.new( options ).name.should == options[:name]
            end
        end
        describe 'when no data is available' do
            it 'return nil' do
                described_class.new( url: options[:url] ).name.should be_nil
            end
        end
    end

    describe '#field_type_for' do
        it 'returns a field\'s type' do
            options =         {
                name:   'login-form',
                url:    "#{url}submit",
                inputs: {
                    'user'          => 'joe',
                    'hidden_field'  => {
                        type:  :hidden,
                        value: 'hidden-value'
                    },
                    'password'      => {
                        id:    'my-password',
                        type:  :password,
                        value: 's3cr3t'
                    }
                }
            }

            e = described_class.new( options )
            e.field_type_for( 'password' ).should     == :password
            e.field_type_for( 'hidden_field' ).should == :hidden
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

                described_class.from_document( url, html ).
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

                described_class.from_document( url, html ).
                    first.requires_password?.should be_false
            end
        end
    end

    describe '#mutation_with_original_values?' do
        context 'when the mutation' do
            context 'is same as the original element' do
                it 'returns true' do
                    inputs = { inputs: { 'param_name' => 'param_value', 'stuff' => nil } }

                    e = described_class.new(
                        url: 'http://test.com',
                        inputs: inputs
                    )

                    has_original ||= false
                    has_sample   ||= false

                    e.mutations( 'seed' ).each do |m|
                        m.url.should    == e.url
                        m.action.should == e.action

                        if m.mutation_with_original_values?
                            m.inputs.should  == e.inputs
                            has_original ||= true
                        end
                    end

                    has_original.should be_true
                end
            end
        end
    end

    describe '#mutation_with_sample_values?' do
        context 'when the mutation' do
            context 'has been filled-in with sample values' do
                it 'returns true' do
                    inputs = { inputs: { 'param_name' => 'param_value', 'stuff' => nil } }
                    e = described_class.new(
                        url: 'http://test.com',
                        inputs: inputs
                    )

                    has_original ||= false
                    has_sample   ||= false

                    e.mutations( 'seed' ).each do |m|
                        m.url.should    == e.url
                        m.action.should == e.action

                        if m.mutation_with_sample_values?
                            m.affected_input_name.should == described_class::SAMPLE_VALUES
                            m.inputs.should == Arachni::Options.input.fill( e.inputs )
                            has_sample ||= true
                        end
                    end

                    has_sample.should be_true
                end
            end
        end
    end

    describe '#mutations' do
        it 'fuzzes #inputs' do
            inputs = { inputs: { 'param_name' => 'param_value', 'stuff' => nil } }
            e = described_class.new(
                url:    'http://test.com',
                inputs: inputs
            )

            checked = false
            e.mutations( 'seed' ).each do |m|
                next if m.mutation_with_original_values? || m.mutation_with_sample_values?

                m.url.should == e.url
                m.action.should == e.action

                m.inputs.should_not == e.inputs
                checked = true
            end

            checked.should be_true
        end

        it 'sets #affected_input_name to the name of the fuzzed input' do
            inputs = { inputs: { 'param_name' => 'param_value', 'stuff' => nil } }
            e = described_class.new(
                url:    'http://test.com',
                inputs: inputs
            )

            checked = false
            e.mutations( 'seed' ).each do |m|
                next if m.mutation_with_original_values? || m.mutation_with_sample_values?

                m.url.should == e.url
                m.action.should == e.action

                m.affected_input_name.should_not == e.affected_input_name
                m.inputs[m.affected_input_name].should include 'seed'

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

                e = described_class.from_document( 'http://test.com', form ).first

                e.mutations( 'seed' ).select do |m|
                    m.inputs['my_pass'] == m.inputs['my_pass_validation']
                end.should be_any
            end
        end

        context 'when it contains select inputs with multiple values' do
            it 'includes mutations with all of them' do
                html = '
                        <html>
                            <body>
                                <form method="get" action="form_action" name="my_form">
                                    <select name="manufacturer">
                                        <option value="volvo">Volvo</option>
                                        <option>Saab</option>
                                        <option value="mercedes">Mercedes</option>
                                        <option value="audi">Audi</option>
                                    </select>
                                    <select name="numbers">
                                        <option value="33">33</option>
                                        <option>22</option>
                                    </select>
                                </form>

                            </body>
                        </html>'

                form = described_class.from_document( url, html ).first

                mutations = form.mutations( '' )

                manufacturers = mutations.map { |f| f['manufacturer'] }
                numbers       = mutations.map { |f| f['numbers'] }

                include = %w(volvo Saab mercedes audi)
                (manufacturers & include).should == include

                include = %w(33 22)
                (numbers & include).should == include
            end
        end

        describe :skip_original do
            it 'does not add mutations with original nor default values' do
                e = described_class.new( options )
                mutations = e.mutations( @seed, skip_original: true )
                mutations.select { |m| m.mutation? }.size.should == 10
            end
        end
    end

    describe '#nonce_name=' do
        it 'sets the name of the input holding the nonce' do
            f = described_class.new( url: url, inputs: { nonce: 'value' } )
            f.nonce_name = 'nonce'
            f.nonce_name.should == 'nonce'
        end

        context 'when there is no input called nonce_name' do
            it 'raises described_class::Error::FieldNotFound' do
                trigger = proc do
                    described_class.new( url: url, inputs: { name: 'value' } ).
                        nonce_name = 'stuff'
                end

                expect { trigger.call }.to raise_error Arachni::Error
                expect { trigger.call }.to raise_error described_class::Error
                expect { trigger.call }.to raise_error described_class::Error::FieldNotFound
            end
        end
    end

    describe '#has_nonce?' do
        context 'when the form has a nonce' do
            it 'returns true' do
                f = described_class.new( url: url, inputs: { nonce: 'value' } )
                f.nonce_name = 'nonce'
                f.has_nonce?.should be_true
            end
        end
        context 'when the form does not have a nonce' do
            it 'returns false' do
                f = described_class.new( url: url, inputs: { nonce: 'value' } )
                f.has_nonce?.should be_false
            end
        end
    end

    describe '#submit' do
        context 'when method is post' do
            it 'performs a POST HTTP request' do
                f = described_class.new(
                    url:    url,
                    method: :post,
                    inputs: options[:inputs]
                )

                body_should = "#{f.method}#{f.inputs.to_s}"
                body = nil

                f.submit { |res| body = res.body }
                http.run
                body_should.should == body
            end
        end
        context 'when method is get' do
            it 'performs a GET HTTP request' do
                f = described_class.new(
                    url:    url,
                    method: :get,
                    inputs: options[:inputs]
                )

                body_should = "#{f.method}#{f.inputs.to_s}"
                body = nil

                f.submit.on_complete { |res| body = res.body }
                http.run
                body_should.should == body
            end
        end
        context 'when the form has a nonce' do
            it 'refreshes its value before submitting it' do
                f = described_class.new(
                    url:    url + 'with_nonce',
                    action: url + 'get_nonce',
                    method: :post,
                    inputs: {
                        'param_name' => 'stuff'
                    }
                )

                f.update 'nonce' => rand( 999 )
                f.nonce_name = 'nonce'

                body = nil

                f.submit { |res| body = res.body }
                http.run
                body.should_not == f.default_inputs['nonce']
                body.to_i.should > 0
            end
        end

    end

    describe '#simple' do
        it 'returns a simplified version of the form attributes and inputs as a Hash' do
            f = described_class.new( options )
            f.update 'user' => 'blah'
            f.simple.should == {
                url:    options[:url],
                action: options[:url],
                name:   'login-form',
                inputs: {
                    'user'         => 'blah',
                    'hidden_field' => 'hidden-value',
                    'password'     => 's3cr3t'
                },
                html: html
            }
        end
    end

    describe '#type' do
        it 'is "form"' do
            described_class.new( options ).type.should == :form
        end
    end

    describe '.from_document' do
        context 'when the response does not contain any forms' do
            it 'returns an empty array' do
                described_class.from_document( '', '' ).should be_empty
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

                    form = described_class.from_document( url, html ).first
                    form.action.should == utilities.normalize_url( url + '/form_action' )
                    form.name.should == 'my_form'
                    form.url.should == url
                    form.method.should == :get
                    form.inputs.should == {
                        'my_first_input'  => 'my_first_value',
                        'my_second_input' => 'my_second_value'
                    }
                    form.inputs.keys.each do |input|
                        form.field_type_for( input ).should == :text
                    end
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

                    form = described_class.from_document( url, html ).first
                    form.action.should == utilities.normalize_url( url + '/form_action' )
                    form.name.should == 'my_form'
                    form.url.should == url
                    form.method.should == :get
                    form.inputs.should == {
                        'vehicle'  => 'Bike',
                        'stuff' => 'Car'
                    }
                    form.inputs.keys.each do |input|
                        form.field_type_for( input ).should == :checkbox
                    end
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

                    form = described_class.from_document( url, html ).first
                    form.action.should == utilities.normalize_url( url + '/form_action' )
                    form.name.should == 'my_form'
                    form.url.should == url
                    form.method.should == :get
                    form.inputs.should == {
                        'my_first_input'  => 'my_first_value',
                        'my_second_input' => 'my_second_value'
                    }
                    form.inputs.keys.each do |input|
                        form.field_type_for( input ).should == :radio
                    end
                end
            end

            context 'with button inputs' do
                it 'returns an array of forms' do
                    html = '
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <button type=submit name="my_button" value="my_button_value" />
                            </form>

                        </body>
                    </html>'

                    form = described_class.from_document( url, html ).first
                    form.action.should == utilities.normalize_url( url + '/form_action' )
                    form.name.should == 'my_form'
                    form.url.should == url
                    form.method.should == :get
                    form.field_type_for( 'my_button' ).should == :submit
                    form.inputs.should == { 'my_button'  => 'my_button_value' }
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

                        form = described_class.from_document( url, html ).first
                        form.action.should == utilities.normalize_url( url + '/form_action' )
                        form.name.should == 'my_form'
                        form.url.should == url
                        form.method.should == :get
                        form.inputs.should == {
                            'manufacturer'  => 'volvo',
                            'numbers'       => '1'
                        }
                        form.inputs.keys.each do |input|
                            form.field_type_for( input ).should == :select
                        end
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

                        form = described_class.from_document( url, html ).first
                        form.action.should == utilities.normalize_url( url + '/form_action' )
                        form.name.should == 'my_form'
                        form.url.should == url
                        form.method.should == :get
                        form.inputs.should == {
                            'manufacturer'  => 'Volvo',
                            'numbers'       => 'One'
                        }
                        form.inputs.keys.each do |input|
                            form.field_type_for( input ).should == :select
                        end
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

                        form = described_class.from_document( url, html ).first
                        form.action.should == utilities.normalize_url( url + '/form_action' )
                        form.name.should == 'my_form'
                        form.url.should == url
                        form.method.should == :get
                        form.inputs.should == {
                            'manufacturer'  => 'Saab',
                            'numbers'       => 'Two'
                        }
                        form.inputs.keys.each do |input|
                            form.field_type_for( input ).should == :select
                        end
                    end
                end

                context 'without any options' do
                    it 'uses an empty value' do
                        html = '
                        <html>
                            <body>
                                <form method="get" action="form_action" name="my_form">
                                    <select name="manufacturer"></select>
                                </form>

                            </body>
                        </html>'

                        form = described_class.from_document( url, html ).first
                        form.action.should == utilities.normalize_url( url + '/form_action' )
                        form.name.should == 'my_form'
                        form.url.should == url
                        form.method.should == :get
                        form.inputs.should == { 'manufacturer' => '' }
                        form.inputs.keys.each do |input|
                            form.field_type_for( input ).should == :select
                        end
                    end
                end


            end

            context 'with a base attribute' do
                it 'respects it and adjust the action accordingly' do
                    base_url = "#{url}/this_is_the_base/"
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

                    forms = described_class.from_document( url, html )
                    forms.size.should == 2

                    form = forms.shift
                    form.action.should == utilities.normalize_url( base_url + 'form_action/is/here')
                    form.name.should == 'my_form!'
                    form.url.should == url
                    form.method.should == :get
                    form.inputs.should == {
                        'text_here' => '',
                        'ha'        => 'hoo'
                    }
                    form.inputs.keys.each do |input|
                        form.field_type_for( input ).should == :text
                    end

                    form = forms.shift
                    form.action.should == utilities.normalize_url( url + '/form_action' )
                    form.name.should == 'my_second_form!'
                    form.url.should == url
                    form.method.should == :post
                    form.inputs.should == { 'text_here' => "my value" }
                    form.inputs.keys.each do |input|
                        form.field_type_for( input ).should == :text
                    end
                end
            end

            context 'which are not properly closed' do
                it 'sanitizes and return an array of forms' do

                    base_url = "#{url}/this_is_the_base/"
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

                    forms = described_class.from_document( url, html )
                    forms.size.should == 3

                    form = forms.shift
                    form.action.should == utilities.normalize_url( base_url + 'form_2' )
                    form.name.should == 'my_form_2'
                    form.url.should == url
                    form.method.should == :get
                    form.inputs.should == { 'text_here' => '' }

                    form = forms.shift
                    form.action.should == utilities.normalize_url( url + '/form' )
                    form.name.should == 'my_form'
                    form.url.should == url
                    form.method.should == :post
                    form.inputs.should == {
                        'form_input_1' => 'form_val_1',
                        'form_input_2' => 'form_val_2'
                    }

                    form = forms.shift
                    form.action.should == utilities.normalize_url( url + '/form_3' )
                    form.name.should == 'my_form_3'
                    form.url.should == url
                    form.method.should == :get
                    form.inputs.should == {
                        'form_3_input_1' => 'form_3_val_1',
                        'manufacturer'   => 'volvo'
                    }
                end
            end

        end
    end

    describe '.encode' do
        it 'form-encodes the passed string' do
            described_class.encode( '% value\ +=&;' ).should == '%25+value%5C+%2B%3D%26%3B'
        end
    end
    describe '#encode' do
        it 'form-encodes the passed string' do
            v = '% value\ +=&;'
            subject.encode( v ).should == described_class.encode( v )
        end
    end

    describe '.decode' do
        it 'form-decodes the passed string' do
            described_class.decode( '%25+value%5C+%2B%3D%26%3B' ).should == '% value\ +=&;'
        end
    end
    describe '#decode' do
        it 'form-decodes the passed string' do
            v = '%25+value%5C+%2B%3D%26%3B'
            subject.decode( v ).should == described_class.decode( v )
        end
    end

    describe '.parse_request_body' do
        it 'form-decodes the passed string' do
            described_class.parse_request_body( 'value%5C+%2B%3D%26%3B=value%5C+%2B%3D%26%3B&testID=53738&deliveryID=53618&testIDs=&deliveryIDs=&selectedRows=2&event=&section=&event%3Dmanage%26amp%3Bsection%3Dexam=Manage+selected+exam' ).should ==
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
            described_class.parse_request_body( 'value%5C+%2B%3D%26%3B=value%5C+%2B%3D%26%3B&testID=53738&deliveryID=53618&testIDs=&deliveryIDs=&selectedRows=2&event=&section=&event%3Dmanage%26amp%3Bsection%3Dexam=Manage+selected+exam' ).should ==
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
