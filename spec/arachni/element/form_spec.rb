require 'spec_helper'

describe Arachni::Element::Form do
    html = '<form method="get" action="form_action" name="my_form">
                <input type=password name="my_first_input" value="my_first_value"" />
                <input type=radio name="my_second_input" value="my_second_value"" />
            </form>'

    it_should_behave_like 'element'
    it_should_behave_like 'with_node'
    it_should_behave_like 'with_dom',  html
    it_should_behave_like 'refreshable'
    it_should_behave_like 'with_source'
    it_should_behave_like 'with_auditor'

    it_should_behave_like 'submittable'
    it_should_behave_like 'inputtable'
    it_should_behave_like 'mutable'
    it_should_behave_like 'auditable'
    it_should_behave_like 'buffered_auditable'
    it_should_behave_like 'line_buffered_auditable'

    before :each do
        @framework ||= Arachni::Framework.new
        @auditor     = Auditor.new( Arachni::Page.from_url( url ), @framework )
    end

    after :each do
        @framework.reset
        reset_options
    end

    let(:auditor) { @auditor }

    def auditable_extract_parameters( resource )
        YAML.load( resource.body )
    end

    def run
        http.run
    end

    subject { described_class.new( options ) }
    let(:inputs) { options[:inputs] }
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
            source: html
        }
    end

    let(:parser) do
        Arachni::Parser.new(
            Arachni::HTTP::Response.new(
                url: url,
                body: form_html,
                headers: {
                    'Content-Type' => 'text/html'
                })
        )
    end

    it 'assigned to Arachni::Form for easy access' do
        expect(Arachni::Form).to eq(described_class)
    end

    describe '#initialize' do
        describe ':method' do
            it 'defaults to :get' do
                expect(described_class.new( url: url ).method).to eq(:get)
            end
        end
        describe ':name' do
            it 'sets #name' do
                expect(described_class.new( url: url, name: 'john' ).name).to eq('john')
            end
        end
        describe ':action' do
            it 'sets #action' do
                action = "#{url}stuff"
                expect(described_class.new( url: url, action: action ).action).to eq(action)
            end

            context 'when nil' do
                it 'defaults to :url' do
                    expect(described_class.new( url: url ).action).to eq(url)
                end
            end
        end
    end

    describe '#mutation_with_original_values?' do
        it 'returns false' do
            expect(subject.mutation_with_original_values?).to be_falsey
        end

        context 'when #mutation_with_original_values' do
            it 'returns true' do
                subject.mutation_with_original_values
                expect(subject.mutation_with_original_values?).to be_truthy
            end
        end
    end

    describe '#mutation_with_sample_values?' do
        it 'returns false' do
            expect(subject.mutation_with_sample_values?).to be_falsey
        end

        context 'when #mutation_with_sample_values' do
            it 'returns true' do
                subject.mutation_with_sample_values
                expect(subject.mutation_with_sample_values?).to be_truthy
            end
        end
    end

    describe '#audit_id' do
        context 'when #force_train?' do
            it 'returns #mutation_id' do
                subject.mutation_with_original_values
                expect(subject.audit_id( 'stuff' )).to eq(subject.id)
            end
        end
    end

    describe '#audit' do
        describe ':each_mutation' do
            it 'ignores #mutation_with_original_values' do
                had_mutation_with_original_values = false
                each_mutation = proc do |mutation|
                    had_mutation_with_original_values ||=
                        mutation.mutation_with_original_values?
                end

                subject.audit( 'stuff', each_mutation: each_mutation ) {}
                subject.http.run

                expect(had_mutation_with_original_values).to be_falsey
            end

            it 'ignores mutation_with_sample_values' do
                had_mutation_with_sample_values = false
                each_mutation = proc do |mutation|
                    had_mutation_with_sample_values ||=
                        mutation.mutation_with_sample_values?
                end

                subject.audit( 'stuff', each_mutation: each_mutation ) {}
                subject.http.run

                expect(had_mutation_with_sample_values).to be_falsey
            end
        end
    end

    describe '#name_or_id' do
        context 'when a #name is available' do
            it 'returns it' do
                expect(described_class.new( url: url, name: 'john' ).
                    name_or_id).to eq('john')
            end
        end

        context 'when a #name is not available' do
            subject { described_class.new( url: url, id: 'john' ) }

            it 'returns the configured :id' do
                expect(subject.name).to be_nil
                expect(subject.name_or_id).to eq('john')
            end
        end

        context 'when no #name nor :id are available' do
            subject { described_class.new( url: url ) }

            it 'returns nil' do
                expect(subject.name_or_id).to be_nil
            end
        end
    end

    describe '#dom' do
        context 'when there are no #inputs' do
            it 'returns nil' do
                subject.inputs = {}
                expect(subject.dom).to be_nil
            end
        end

        context 'when there is no #node' do
            it 'returns nil' do
                subject.source = nil
                expect(subject.dom).to be_nil
            end
        end
    end

    describe '#force_train?' do
        it 'returns false' do
            expect(subject.force_train?).to be_falsey
        end

        context 'when #mutation_with_original_values?' do
            it 'returns true' do
                subject.mutation_with_original_values
                expect(subject.force_train?).to be_truthy
            end
        end
        context 'when #mutation_with_sample_values?' do
            it 'returns true' do
                subject.mutation_with_sample_values
                expect(subject.force_train?).to be_truthy
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
            describe ':get' do
                let(:method) { :get }

                it 'removes the URL query' do
                    expect(subject.action).to eq(url)
                end

                it 'merges the URL query parameters with the given :inputs' do
                    expect(subject.inputs).to eq(query_inputs.merge( option_inputs ))
                end

                context 'when URL query parameters and :inputs have the same name' do
                    let(:option_inputs) do
                        {
                            'stuff'          => 'here3',
                            'yet-more-stuff' => 'here4'
                        }
                    end

                    it 'it gives precedence to the :inputs' do
                        expect(subject.inputs).to eq(query_inputs.merge( option_inputs ))
                    end
                end
            end

            describe ':post' do
                let(:method) { :post }

                it 'preserves the URL query' do
                    expect(subject.action).to eq(action)
                end

                it 'ignores the URL query parameters' do
                    expect(subject.inputs).to eq(option_inputs)
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

                expect(described_class.new( options ).details_for( :password )).to eq(
                    options[:inputs]['password']
                )
            end
        end
        describe 'when no data is available' do
            it 'return nil' do
                expect(described_class.new( options ).details_for( :username )).to eq({})
            end
        end
    end

    describe '#name' do
        context 'when there is a form name' do
            it 'returns it' do
                expect(described_class.new( options ).name).to eq(options[:name])
            end
        end
        describe 'when no data is available' do
            it 'return nil' do
                expect(described_class.new( url: options[:url] ).name).to be_nil
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
            expect(e.field_type_for( 'password' )).to     eq(:password)
            expect(e.field_type_for( 'hidden_field' )).to eq(:hidden)
        end
    end

    describe '#requires_password?' do
        context 'when the form has a password field' do
            let(:form_html) do
                '
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <input type=password name="my_first_input" value="my_first_value"" />
                                <input type=radio name="my_second_input" value="my_second_value"" />
                            </form>

                        </body>
                    </html>'
            end

            it 'returns true' do
                expect(described_class.from_parser( parser ).
                    first.requires_password?).to be_truthy
            end
        end

        context 'when the form does not have a password field' do
            let(:form_html) do
                '
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <input type=radio name="my_second_input" value="my_second_value"" />
                            </form>

                        </body>
                    </html>'
            end

            it 'returns false' do
                expect(described_class.from_parser( parser ).
                    first.requires_password?).to be_falsey
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
                        expect(m.url).to    eq(e.url)
                        expect(m.action).to eq(e.action)

                        if m.mutation_with_original_values?
                            expect(m.inputs).to  eq(e.inputs)
                            has_original ||= true
                        end
                    end

                    expect(has_original).to be_truthy
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
                        expect(m.url).to    eq(e.url)
                        expect(m.action).to eq(e.action)

                        if m.mutation_with_sample_values?
                            expect(m.affected_input_name).to eq(described_class::SAMPLE_VALUES)
                            expect(m.inputs).to eq(Arachni::Options.input.fill( e.inputs ))
                            has_sample ||= true
                        end
                    end

                    expect(has_sample).to be_truthy
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

                expect(m.url).to eq(e.url)
                expect(m.action).to eq(e.action)

                expect(m.inputs).not_to eq(e.inputs)
                checked = true
            end

            expect(checked).to be_truthy
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

                expect(m.url).to eq(e.url)
                expect(m.action).to eq(e.action)

                expect(m.affected_input_name).not_to eq(e.affected_input_name)
                expect(m.inputs[m.affected_input_name]).to include 'seed'

                checked = true
            end

            expect(checked).to be_truthy
        end

        context 'when it contains more than 1 password field' do
            let(:form_html) do
                <<-EOHTML
                    <form>
                        <input type="password" name="my_pass" />
                        <input type="password" name="my_pass_validation" />
                    </form>
                EOHTML
            end

            it 'includes mutations which have the same values for all of them' do
                e = described_class.from_parser( parser ).first

                expect(e.mutations( 'seed' ).select do |m|
                    m.inputs['my_pass'] == m.inputs['my_pass_validation']
                end).to be_any
            end
        end

        context 'when it contains select inputs with multiple values' do
            let(:form_html) do
                '
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
            end

            it 'includes mutations with all of them' do
                form = described_class.from_parser( parser ).first

                mutations = form.mutations( '' )

                manufacturers = mutations.map { |f| f['manufacturer'] }
                numbers       = mutations.map { |f| f['numbers'] }

                include = %w(volvo Saab mercedes audi)
                expect(manufacturers & include).to eq(include)

                include = %w(33 22)
                expect(numbers & include).to eq(include)
            end
        end

        describe ':skip_original' do
            it 'does not add mutations with original nor default values' do
                e = described_class.new( options )
                mutations = e.mutations( @seed, skip_original: true )
                expect(mutations.select { |m| m.mutation? }.size).to eq(10)
            end
        end
    end

    describe '#nonce_name=' do
        it 'sets the name of the input holding the nonce' do
            f = described_class.new( url: url, inputs: { nonce: 'value' } )
            f.nonce_name = 'nonce'
            expect(f.nonce_name).to eq('nonce')
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
                expect(f.has_nonce?).to be_truthy
            end
        end
        context 'when the form does not have a nonce' do
            it 'returns false' do
                f = described_class.new( url: url, inputs: { nonce: 'value' } )
                expect(f.has_nonce?).to be_falsey
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
                expect(body_should).to eq(body)
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
                expect(body_should).to eq(body)
            end
        end
        context 'when the form has a nonce' do
            subject do
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
                f
            end

            it 'refreshes its value before submitting it' do
                body = nil

                subject.submit { |res| body = res.body }
                http.run
                expect(body).not_to eq(subject.default_inputs['nonce'])
                expect(body.to_i).to be > 0
            end

            context 'and it could not refresh it' do
                it 'submits it anyway' do
                    body = nil

                    allow(subject).to receive(:refresh) { nil }
                    subject.submit { |res| body = res.body }
                    http.run

                    expect(body).not_to eq(subject.default_inputs['nonce'])
                    expect(body.to_i).to be > 0
                end
            end
        end
    end

    describe '#simple' do
        it 'returns a simplified version of the form attributes and inputs as a Hash' do
            f = described_class.new( options )
            f.update 'user' => 'blah'
            expect(f.simple).to eq({
                url:    options[:url],
                action: options[:url],
                name:   'login-form',
                inputs: {
                    'user'         => 'blah',
                    'hidden_field' => 'hidden-value',
                    'password'     => 's3cr3t'
                },
                source: html
            })
        end
    end

    describe '#type' do
        it 'is "form"' do
            expect(described_class.new( options ).type).to eq(:form)
        end
    end

    describe '.from_parser' do
        context 'when the response does not contain any forms' do
            let(:form_html) do
                ''
            end

            it 'returns an empty array' do
                expect(described_class.from_parser( parser )).to be_empty
            end
        end

        context 'when forms have actions that are out of scope' do
            let(:form_html) do
                <<EOHTML
                    <html>
                        <body>
                            <form method="get" action="form_action/exclude" name="my_form">
                                <input name="my_first_input" value="my_first_value" />
                                <input name="my_second_input" value="my_second_value" />
                            </form>

                            #{html}
                        </body>
                    </html>
EOHTML
            end

            it 'ignores them' do
                Arachni::Options.scope.exclude_path_patterns = [/exclude/]

                forms = described_class.from_parser( parser )
                expect(forms.size).to eq(1)
                expect(forms.first.action).to eq(utilities.normalize_url( url + '/form_action' ))
            end

            context 'when ignore_scope is set' do
                it 'includes them' do
                    Arachni::Options.scope.exclude_path_patterns = [/exclude/]

                    forms = described_class.from_parser( parser, true )
                    expect(forms.size).to eq(2)
                end
            end
        end

        context 'when the response contains forms' do
            context 'with text inputs' do
                let(:form_html) do
                    '
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <input name="my_first_input" value="my_first_value" />
                                <input name="my_second_input" value="my_second_value" />
                            </form>

                        </body>
                    </html>'
                end

                it 'returns an array of forms' do
                    form = described_class.from_parser( parser ).first
                    expect(form.action).to eq(utilities.normalize_url( url + '/form_action' ))
                    expect(form.name).to eq('my_form')
                    expect(form.url).to eq(url)
                    expect(form.method).to eq(:get)
                    expect(form.inputs).to eq({
                        'my_first_input'  => 'my_first_value',
                        'my_second_input' => 'my_second_value'
                    })
                    form.inputs.keys.each do |input|
                        expect(form.field_type_for( input )).to eq(:text)
                    end
                end
            end

            context 'with checkbox inputs' do
                let(:form_html) do
                    '
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <input type="checkbox" name="vehicle" value="Bike">
                                <input type="checkbox" name="stuff" value="Car">
                            </form>

                        </body>
                    </html>'
                end

                it 'returns an array of forms' do
                    form = described_class.from_parser( parser ).first
                    expect(form.action).to eq(utilities.normalize_url( url + '/form_action' ))
                    expect(form.name).to eq('my_form')
                    expect(form.url).to eq(url)
                    expect(form.method).to eq(:get)
                    expect(form.inputs).to eq({
                        'vehicle'  => 'Bike',
                        'stuff' => 'Car'
                    })
                    form.inputs.keys.each do |input|
                        expect(form.field_type_for( input )).to eq(:checkbox)
                    end
                end
            end

            context 'with radio inputs' do
                let(:form_html) do
                    '
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <input type=radio name="my_first_input" value="my_first_value"" />
                                <input type=radio name="my_second_input" value="my_second_value"" />
                            </form>

                        </body>
                    </html>'
                end

                it 'returns an array of forms' do
                    form = described_class.from_parser( parser ).first
                    expect(form.action).to eq(utilities.normalize_url( url + '/form_action' ))
                    expect(form.name).to eq('my_form')
                    expect(form.url).to eq(url)
                    expect(form.method).to eq(:get)
                    expect(form.inputs).to eq({
                        'my_first_input'  => 'my_first_value',
                        'my_second_input' => 'my_second_value'
                    })
                    form.inputs.keys.each do |input|
                        expect(form.field_type_for( input )).to eq(:radio)
                    end
                end
            end

            context 'with button inputs' do
                let(:form_html) do
                    '
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <button type=submit name="my_button" value="my_button_value" />
                            </form>

                        </body>
                    </html>'
                end

                it 'returns an array of forms' do
                    form = described_class.from_parser( parser ).first
                    expect(form.action).to eq(utilities.normalize_url( url + '/form_action' ))
                    expect(form.name).to eq('my_form')
                    expect(form.url).to eq(url)
                    expect(form.method).to eq(:get)
                    expect(form.field_type_for( 'my_button' )).to eq(:submit)
                    expect(form.inputs).to eq({ 'my_button'  => 'my_button_value' })
                end
            end

            context 'with multiple submit inputs' do
                let(:form_html) do
                    '
                    <html>
                        <body>
                            <form method="get" action="form_action" name="my_form">
                                <input type=submit name="choice" value="value 1" />
                                <input type=submit name="choice" value="value 2" />
                            </form>
                        </body>
                    </html>'
                end

                it 'returns forms for each value' do
                    forms = described_class.from_parser( parser )
                    expect(forms.size).to eq(2)

                    form = forms.first
                    expect(form.action).to eq(utilities.normalize_url( url + '/form_action' ))
                    expect(form.name).to eq('my_form')
                    expect(form.url).to eq(url)
                    expect(form.method).to eq(:get)
                    expect(form.field_type_for( 'choice' )).to eq(:submit)
                    expect(form.inputs['choice']).to eq('value 1')

                    form = forms[1]
                    expect(form.action).to eq(utilities.normalize_url( url + '/form_action' ))
                    expect(form.name).to eq('my_form')
                    expect(form.url).to eq(url)
                    expect(form.method).to eq(:get)
                    expect(form.field_type_for( 'choice' )).to eq(:submit)
                    expect(form.inputs['choice']).to eq('value 2')
                end
            end

            context 'with selects' do
                context 'with values' do
                    let(:form_html) do
                        '
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
                    end

                    it 'returns an array of forms' do
                        form = described_class.from_parser( parser ).first
                        expect(form.action).to eq(utilities.normalize_url( url + '/form_action' ))
                        expect(form.name).to eq('my_form')
                        expect(form.url).to eq(url)
                        expect(form.method).to eq(:get)
                        expect(form.inputs).to eq({
                            'manufacturer'  => 'volvo',
                            'numbers'       => '1'
                        })
                        form.inputs.keys.each do |input|
                            expect(form.field_type_for( input )).to eq(:select)
                        end
                    end
                end

                context 'without values' do
                    let(:form_html) do
                        '
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
                    end

                    it 'uses the element texts' do
                        form = described_class.from_parser( parser ).first
                        expect(form.action).to eq(utilities.normalize_url( url + '/form_action' ))
                        expect(form.name).to eq('my_form')
                        expect(form.url).to eq(url)
                        expect(form.method).to eq(:get)
                        expect(form.inputs).to eq({
                            'manufacturer'  => 'Volvo',
                            'numbers'       => 'One'
                        })
                        form.inputs.keys.each do |input|
                            expect(form.field_type_for( input )).to eq(:select)
                        end
                    end
                end

                context 'with selected options' do
                    let(:form_html) do
                        '
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
                    end

                    it 'uses their values' do
                        form = described_class.from_parser( parser ).first
                        expect(form.action).to eq(utilities.normalize_url( url + '/form_action' ))
                        expect(form.name).to eq('my_form')
                        expect(form.url).to eq(url)
                        expect(form.method).to eq(:get)
                        expect(form.inputs).to eq({
                            'manufacturer'  => 'Saab',
                            'numbers'       => 'Two'
                        })
                        form.inputs.keys.each do |input|
                            expect(form.field_type_for( input )).to eq(:select)
                        end
                    end
                end

                context 'without any options' do
                    let(:form_html) do
                        '
                        <html>
                            <body>
                                <form method="get" action="form_action" name="my_form">
                                    <select name="manufacturer"></select>
                                </form>

                            </body>
                        </html>'
                    end

                    it 'uses an empty value' do
                        form = described_class.from_parser( parser ).first
                        expect(form.action).to eq(utilities.normalize_url( url + '/form_action' ))
                        expect(form.name).to eq('my_form')
                        expect(form.url).to eq(url)
                        expect(form.method).to eq(:get)
                        expect(form.inputs).to eq({ 'manufacturer' => '' })
                        form.inputs.keys.each do |input|
                            expect(form.field_type_for( input )).to eq(:select)
                        end
                    end
                end
            end

            context 'with a base attribute' do
                let(:base_url) { "/this_is_the_base/" }
                let(:form_html) do
                    '
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
                end

                it 'respects it and adjust the action accordingly' do
                    forms = described_class.from_parser( parser )
                    expect(forms.size).to eq(2)

                    form = forms.shift
                    expect(form.action).to eq(utilities.normalize_url( url + base_url + 'form_action/is/here'))
                    expect(form.name).to eq('my_form!')
                    expect(form.url).to eq(url)
                    expect(form.method).to eq(:get)
                    expect(form.inputs).to eq({
                        'text_here' => '',
                        'ha'        => 'hoo'
                    })
                    form.inputs.keys.each do |input|
                        expect(form.field_type_for( input )).to eq(:text)
                    end

                    form = forms.shift
                    expect(form.action).to eq(utilities.normalize_url( url + '/form_action' ))
                    expect(form.name).to eq('my_second_form!')
                    expect(form.url).to eq(url)
                    expect(form.method).to eq(:post)
                    expect(form.inputs).to eq({ 'text_here' => "my value" })
                    form.inputs.keys.each do |input|
                        expect(form.field_type_for( input )).to eq(:text)
                    end
                end
            end

            context 'which are not properly closed' do
                let(:base_url) { "/this_is_the_base/" }
                let(:form_html) do
                    '
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
                end

                it 'sanitizes and return an array of forms' do
                    forms = described_class.from_parser( parser )
                    expect(forms.size).to eq(3)

                    form = forms.shift
                    expect(form.action).to eq(utilities.to_absolute( base_url + 'form_2', url ))
                    expect(form.name).to eq('my_form_2')
                    expect(form.url).to eq(url)
                    expect(form.method).to eq(:get)
                    expect(form.inputs).to eq({ 'text_here' => '' })

                    form = forms.shift
                    expect(form.action).to eq(utilities.normalize_url( url + '/form' ))
                    expect(form.name).to eq('my_form')
                    expect(form.url).to eq(url)
                    expect(form.method).to eq(:post)
                    expect(form.inputs).to eq({
                        'form_input_1' => 'form_val_1',
                        'form_input_2' => 'form_val_2'
                    })

                    form = forms.shift
                    expect(form.action).to eq(utilities.normalize_url( url + '/form_3' ))
                    expect(form.name).to eq('my_form_3')
                    expect(form.url).to eq(url)
                    expect(form.method).to eq(:get)
                    expect(form.inputs).to eq({
                        'form_3_input_1' => 'form_3_val_1',
                        'manufacturer'   => 'volvo'
                    })
                end
            end

            context 'when its value is' do
                let(:form) { described_class.from_parser( parser ).first }
                let(:value) { 'a' * size }
                let(:form_html) do
                    '<html>
                        <body>
                            <form method="post" action="/form" name="my_form">
                                <input type="text" name="input_1" value="' + value + '">
                                <input type="text" name="input_2" value="val_2">
                                <input type="submit">
                            </form>
                        </body>
                    </html>'
                end

                context "equal to #{described_class::MAX_SIZE}" do
                    let(:size) { described_class::MAX_SIZE }

                    it 'returns empty array' do
                        expect(form.inputs['input_1']).to be_empty
                        expect(form.inputs['input_2']).to eq('val_2')
                    end
                end

                context "larger than #{described_class::MAX_SIZE}" do
                    let(:size) { described_class::MAX_SIZE + 1 }

                    it 'sets empty value' do
                        expect(form.inputs['input_1']).to be_empty
                        expect(form.inputs['input_2']).to eq('val_2')
                    end
                end

                context "smaller than #{described_class::MAX_SIZE}" do
                    let(:size) { described_class::MAX_SIZE - 1 }

                    it 'leaves the values alone' do
                        expect(form.inputs['input_1']).to eq(value)
                        expect(form.inputs['input_2']).to eq('val_2')
                    end
                end
            end
        end
    end

    describe '.parse_data' do
        let(:body) do
            "--myboundary\r\nContent-Disposition: form-data; name=\"name1\"\r\n\r\nval1\r\n--myboundary\r\nContent-Disposition: form-data; name=\"name2\"\r\n\r\nval2\r\n--myboundary--\r\n"
        end

        it 'parses the #body' do
            expect(described_class.parse_data( body, 'myboundary' )).to eq({
                'name1'    => 'val1',
                'name2'    => 'val2'
            })
        end

        context 'when boundary is' do
            context 'nil' do
                it 'returns empty hash' do
                    expect(described_class.parse_data( body, nil )).to be_empty
                end
            end

            context 'empty' do
                it 'returns empty hash' do
                    expect(described_class.parse_data( body, '' )).to be_empty
                end
            end
        end

        context 'when the body is incomplete' do
            let(:body) do
                "--myboundary\r\nContent-Disposition: form-data; name=\"name1\"\r\n\r\nval1\r\n--myboundary\r\nContent-Disposition: form-data; name=\"name2\"\r\n\r\nval2\r\n"
            end

            it 'returns partial data' do
                expect(described_class.parse_data( body, 'myboundary' )).to eq({
                    'name1' => 'val1'
                })
            end
        end

        context 'when there are multiple identical names' do
            let(:body) do
                "--myboundary\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nval1\r\n--myboundary\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nval2\r\n--myboundary--\r\n"
            end

            it 'keeps the first value' do
                expect(described_class.parse_data( body, 'myboundary' )).to eq({
                    'name' => 'val1'
                })
            end
        end

        context 'when there is an array param' do
            let(:body) do
                "--myboundary\r\nContent-Disposition: form-data; name=\"name[]\"\r\n\r\nval1\r\n--myboundary\r\nContent-Disposition: form-data; name=\"name[]\"\r\n\r\nval2\r\n--myboundary--\r\n"
            end

            it 'keeps the first value' do
                expect(described_class.parse_data( body, 'myboundary' )).to eq({
                    'name[]' => 'val1'
                })
            end
        end
    end

    describe '.encode' do
        it 'form-encodes the passed string' do
            expect(described_class.encode( '% value\ +=&;' )).to eq('%25%20value%5C%20%2B%3D%26%3B')
        end
    end
    describe '#encode' do
        it 'form-encodes the passed string' do
            v = '% value\ +=&;'
            expect(subject.encode( v )).to eq(described_class.encode( v ))
        end
    end

    describe '.decode' do
        it 'form-decodes the passed string' do
            expect(described_class.decode( '%25%20value%5C%20%2B%3D%26%3B' )).to eq('% value\ +=&;')
        end

        it 'handles broken encodings' do
            expect(described_class.decode( '%g' )).to eq('%g')
        end
    end
    describe '#decode' do
        it 'form-decodes the passed string' do
            v = '%25%20value%5C%20%2B%3D%26%3B'
            expect(subject.decode( v )).to eq(described_class.decode( v ))
        end
    end

end
