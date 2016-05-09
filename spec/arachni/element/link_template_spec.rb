require 'spec_helper'

describe Arachni::Element::LinkTemplate do
    html = "<a href='http://test.com/#/param/val'>stuff</a>"

    it_should_behave_like 'element'
    it_should_behave_like 'with_node'
    it_should_behave_like 'with_dom',  html
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
    end

    let(:auditor) { @auditor }

    before :each do
        Arachni::Options.audit.link_templates = /param\/(?<param>\w+)/
    end

    def auditable_extract_parameters( resource )
        YAML.load( resource.body )
    end

    def run
        http.run
    end

    after :each do
        reset_options
    end

    subject do
        described_class.new(
            url:      url_with_inputs,
            template: template,
            source:   html
        )
    end
    let(:inputtable) do
        described_class.new(
            url:      "#{url}input1/value1/input2/value2",
            template: /input1\/(?<input1>\w+)\/input2\/(?<input2>\w+)/
        )
    end
    let(:mutable){ inputtable }
    let(:url_with_inputs) { "#{url}param/val" }
    let(:template) { /param\/(?<param>\w+)/ }
    let(:inputs) { { 'param' => 'val' } }
    let(:url) { utilities.normalize_url( web_server_url_for( :link_template ) ) }
    let(:http) { Arachni::HTTP::Client }
    let(:utilities) { Arachni::Utilities }

    describe '#initialize' do
        describe ':options' do
            describe ':template' do
                it 'sets the #template' do
                    expect(described_class.new(
                        url:      url_with_inputs,
                        template: template
                    ).template).to eq(template)
                end
            end

            describe ':inputs' do
                it 'sets the #inputs' do
                    expect(described_class.new(
                        url:      url_with_inputs,
                        inputs:   inputs,
                        template: template
                    ).inputs).to eq(inputs)
                end
            end

            context 'when no :inputs are provided' do
                it 'uses the given :template to extract them' do
                    expect(described_class.new(
                        url:      url_with_inputs,
                        template: template
                    ).inputs).to eq(inputs)
                end

                context 'when no :template is provided' do
                    it "tries to match one of #{Arachni::OptionGroups::Audit}#link_templates" do
                        Arachni::Options.audit.link_templates = template

                        l = described_class.new( url: url_with_inputs )
                        expect(l.inputs).to eq(inputs)
                        expect(l.template).to eq(template)
                    end
                end
            end
        end
    end

    describe '#simple' do
        it 'returns a simple hash representation' do
            expect(subject.simple).to eq({
                subject.action => subject.inputs
            })
        end
    end

    describe '#valid_input_name?' do
        context 'when the name can be found in the #template named captures' do
            it 'returns true' do
                expect(subject.template.names).to be_any

                subject.template.names.each do |name|
                    expect(subject.valid_input_name?( name )).to be_truthy
                end
            end
        end

        context 'when the name cannot be found in the #template named captures' do
            it 'returns false' do
                expect(subject.valid_input_name?( 'stuff' )).to be_falsey
            end
        end
    end

    describe '#valid_input_data?' do
        it 'returns true' do
            expect(subject.valid_input_data?( 'stuff' )).to be_truthy
        end

        described_class::INVALID_INPUT_DATA.each do |invalid_data|
            context "when the value contains #{invalid_data.inspect}" do
                it 'returns false' do
                    expect(subject.valid_input_data?( "stuff #{invalid_data}" )).to be_falsey
                end
            end
        end
    end

    describe '#dom' do
        context 'when there are no DOM#inputs' do
            it 'returns nil' do
                subject.source = '<a href="/stuff">Bla</a>'
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

    describe '#to_s' do
        it 'returns the updated link' do
            expect(inputtable.to_s).to eq(inputtable.action)

            inputtable.inputs = {
                'input1' => 'new value 1',
                'input2' => 'new value 2'
            }

            expect(inputtable.to_s).to eq("#{url}input1/new%20value%201/input2/new%20value%202")
        end
    end

    describe '#coverage_id' do
        it "takes into account #{described_class::DOM}#template names" do
            e = subject.dup
            e.source ="<a href='http://test.com/#/param/val'>stuff</a>"

            c = subject.dup
            c.source ="<a href='http://test.com/#/param/val2'>stuff</a>"

            expect(c.coverage_id).to eq(e.coverage_id)

            e = subject.dup
            e.source ="<a href='http://test.com/#/param/val'>stuff</a>"

            Arachni::Options.audit.link_templates << /param2\/(?<param2>\w+)/

            c = subject.dup
            c.source ="<a href='http://test.com/#/param2/val'>stuff</a>"

            expect(c.coverage_id).not_to eq(e.coverage_id)
        end
    end

    describe '#id' do
        it "takes into account #{described_class::DOM}#inputs" do
            e = subject.dup
            e.source ="<a href='http://test.com/#/param/val'>stuff</a>"

            c = subject.dup
            c.source ="<a href='http://test.com/#/param/val'>stuff</a>"

            expect(c.id).to eq(e.id)

            e = subject.dup
            e.source ="<a href='http://test.com/#/param/val'>stuff</a>"

            c = subject.dup
            c.source ="<a href='http://test.com/#/param/val1'>stuff</a>"

            expect(c.id).not_to eq(e.id)

            e = subject.dup
            e.source ="<a href='http://test.com/#/param/val'>stuff</a>"

            c = subject.dup
            c.source ="<a href='http://test.com/#/param2/val'>stuff</a>"

            expect(c.id).not_to eq(e.id)
        end
    end

    describe '#to_rpc_data' do
        it "does not include 'dom_data'" do
            subject.source = html
            expect(subject.dom).to be_truthy

            expect(subject.to_rpc_data).not_to include 'dom_data'
        end
    end

    describe '.encode' do
        it 'URL-encodes the passed string' do
            expect(described_class.encode( 'test/;' )).to eq('test%2F%3B')
        end
    end

    describe '.decode' do
        it 'URL-decodes the passed string' do
            v = '%25+value%5C+%2B%3D%26%3B'
            expect(described_class.decode( v )).to eq(URI.decode( v ))
        end
    end
    describe '#decode' do
        it 'URL-decodes the passed string' do
            v = '%25+value%5C+%2B%3D%26%3B'
            expect(subject.decode( v )).to eq(described_class.decode( v ))
        end
    end

    describe '.extract_inputs' do
        it 'returns a hash of inputs and the matching template' do
            url       = "#{url}input1/value1/input2/value2"
            templates = [/input1\/(?<input1>\w+)\/input2\/(?<input2>\w+)/]

            template, inputs = described_class.extract_inputs( url, templates )
            expect(templates).to eq([template])
            expect(inputs).to eq({
                'input1' => 'value1',
                'input2' => 'value2'
            })
        end

        it 'decodes the input values' do
            url       = "#{url}input1/val%20ue1/input2/val%20ue2"
            templates = [/input1\/(?<input1>.+)\/input2\/(?<input2>.+)/]

            _, inputs = described_class.extract_inputs( url, templates )
            expect(inputs).to eq({
                'input1' => 'val ue1',
                'input2' => 'val ue2'
            })
        end

        context 'when no URL is given' do
            it 'returns an empty array' do
                expect(described_class.extract_inputs( nil )).to eq([])
            end
        end

        context 'when no templates are given' do
            it "defaults to #{Arachni::OptionGroups::Audit}#link_templates" do
                url       = "#{url}input1/value1/input2/value2"
                templates = [/input1\/(?<input1>\w+)\/input2\/(?<input2>\w+)/]

                Arachni::Options.audit.link_templates = templates

                template, inputs = described_class.extract_inputs( url )
                expect(inputs).to eq({
                    'input1' => 'value1',
                    'input2' => 'value2'
                })

                expect([templates]).to eq([Arachni::Options.audit.link_templates])
            end
        end

        context 'when no matches are found' do
            it 'returns an empty array' do
                url       = "#{url}input3/value1/input4/value2"
                templates = [/input1\/(?<input1>\w+)\/input2\/(?<input2>\w+)/]

                expect(described_class.extract_inputs( url, templates )).to eq([])
            end
        end
    end

    describe '.type' do
        it 'returns :link_template' do
            expect(described_class.type).to eq(:link_template)
        end
    end

    describe '.from_response' do
        it 'returns an array of link template from the response' do
            response = Arachni::HTTP::Response.new(
                url: url,
                body: '
                <html>
                    <body>
                        <a href="' + url + '/test2/param/myvalue"></a>
                    </body>
                </html>'
            )

            link = described_class.from_response( response ).first
            expect(link.action).to eq(url + 'test2/param/myvalue')
            expect(link.url).to eq(url)
            expect(link.inputs).to eq({
                'param'  => 'myvalue'
            })
        end

        context 'when the URL matches a link template' do
            it 'includes it' do
                response = Arachni::HTTP::Response.new(
                    url: url + '/test2/param/myvalue'
                )

                link = described_class.from_response( response ).first
                expect(link.action).to eq(url + 'test2/param/myvalue')
                expect(link.url).to eq(link.action)
                expect(link.inputs).to eq({
                    'param'  => 'myvalue'
                })
            end
        end
    end

    describe '.from_parser' do
        let(:parser) do
            Arachni::Parser.new(
                Arachni::HTTP::Response.new(
                    url: url,
                    body: link_html,
                    headers: {
                        'Content-Type' => 'text/html'
                    })
            )
        end

        context 'when the response does not contain any link templates' do
            let(:link_html) do
                ''
            end

            it 'returns an empty array' do
                expect(described_class.from_parser( parser )).to be_empty
            end
        end
        context 'when links have actions that are out of scope' do
            let(:link_html) do
                '
                    <html>
                        <body>
                            <a href="' + url + '/test2/param/exclude"></a>

                            <a href="' + url + '/test2/param/myvalue"></a>
                        </body>
                    </html>'
            end

            it 'ignores them' do
                Arachni::Options.scope.exclude_path_patterns = [/exclude/]

                links = described_class.from_parser( parser )
                expect(links.size).to eq(1)
                expect(links.first.action).to eq(url + 'test2/param/myvalue')
            end
        end

        context 'when the response contains link templates' do
            let(:link_html) do
                '
                <html>
                    <body>
                        <a href="' + url + '/test2/param/myvalue"></a>
                    </body>
                </html>'
            end

            it 'returns an array of link templates' do
                link = described_class.from_parser( parser ).first
                expect(link.action).to eq(url + 'test2/param/myvalue')
                expect(link.url).to eq(url)
                expect(link.inputs).to eq({
                    'param'  => 'myvalue'
                })
            end

            context 'and includes a base attribute' do
                let(:link_html) do
                    '
                    <html>
                        <head>
                            <base href="' + base_url + '" />
                        </head>
                        <body>
                            <a href="test/param/myvalue"></a>
                        </body>
                    </html>'
                end
                let(:base_url) { "#{url}this_is_the_base/" }

                it 'should return an array of link templates with adjusted URIs' do
                    link = described_class.from_parser( parser ).first
                    expect(link.action).to eq(base_url + 'test/param/myvalue')
                    expect(link.url).to eq(url)
                    expect(link.inputs).to eq({
                        'param'  => 'myvalue'
                    })
                end
            end
        end
    end
end
