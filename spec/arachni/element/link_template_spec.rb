require 'spec_helper'

describe Arachni::Element::LinkTemplate do
    html = "<a href='http://test.com/#/param/val'>stuff</a>"

    it_should_behave_like 'element'
    it_should_behave_like 'with_node', html
    it_should_behave_like 'with_dom',  html
    it_should_behave_like 'auditable'

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
            template: template
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
        describe :options do
            describe :template do
                it 'sets the #template' do
                    described_class.new(
                        url:      url_with_inputs,
                        template: template
                    ).template.should == template
                end
            end

            describe :inputs do
                it 'sets the #inputs' do
                    described_class.new(
                        url:      url_with_inputs,
                        inputs:   inputs,
                        template: template
                    ).inputs.should == inputs
                end
            end

            context 'when no :inputs are provided' do
                it 'uses the given :template to extract them' do
                    described_class.new(
                        url:      url_with_inputs,
                        template: template
                    ).inputs.should == inputs
                end

                context 'when no :template is provided' do
                    it "tries to match one of #{Arachni::OptionGroups::Audit}#link_templates" do
                        Arachni::Options.audit.link_templates = template

                        l = described_class.new( url: url_with_inputs )
                        l.inputs.should == inputs
                        l.template.should == template
                    end
                end
            end
        end
    end

    describe '#simple' do
        it 'returns a simple hash representation' do
            subject.simple.should == {
                subject.action => subject.inputs
            }
        end
    end

    describe '#valid_input_name?' do
        context 'when the name can be found in the #template named captures' do
            it 'returns true' do
                subject.template.names.should be_any

                subject.template.names.each do |name|
                    subject.valid_input_name?( name ).should be_true
                end
            end
        end

        context 'when the name cannot be found in the #template named captures' do
            it 'returns false' do
                subject.valid_input_name?( 'stuff' ).should be_false
            end
        end
    end

    describe '#valid_input_data?' do
        it 'returns true' do
            subject.valid_input_data?( 'stuff' ).should be_true
        end

        described_class::INVALID_INPUT_DATA.each do |invalid_data|
            context "when the value contains #{invalid_data.inspect}" do
                it 'returns false' do
                    subject.valid_input_data?( "stuff #{invalid_data}" ).should be_false
                end
            end
        end
    end

    describe '#dom' do
        context 'when there are no DOM#inputs' do
            it 'returns nil' do
                subject.html = '<a href="/stuff">Bla</a>'
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

    describe '#to_s' do
        it 'returns the updated link' do
            inputtable.to_s.should == inputtable.action

            inputtable.inputs = {
                'input1' => 'new value 1',
                'input2' => 'new value 2'
            }

            inputtable.to_s.should == "#{url}input1/new%20value%201/input2/new%20value%202"
        end
    end

    describe '#coverage_id' do
        it "takes into account #{described_class::DOM}#template names" do
            e = subject.dup
            e.html = "<a href='http://test.com/#/param/val'>stuff</a>"

            c = subject.dup
            c.html = "<a href='http://test.com/#/param/val2'>stuff</a>"

            c.coverage_id.should == e.coverage_id

            e = subject.dup
            e.html = "<a href='http://test.com/#/param/val'>stuff</a>"

            Arachni::Options.audit.link_templates << /param2\/(?<param2>\w+)/

            c = subject.dup
            c.html = "<a href='http://test.com/#/param2/val'>stuff</a>"

            c.coverage_id.should_not == e.coverage_id
        end
    end

    describe '#id' do
        it "takes into account #{described_class::DOM}#inputs" do
            e = subject.dup
            e.html = "<a href='http://test.com/#/param/val'>stuff</a>"

            c = subject.dup
            c.html = "<a href='http://test.com/#/param/val'>stuff</a>"

            c.id.should == e.id

            e = subject.dup
            e.html = "<a href='http://test.com/#/param/val'>stuff</a>"

            c = subject.dup
            c.html = "<a href='http://test.com/#/param/val1'>stuff</a>"

            c.id.should_not == e.id

            e = subject.dup
            e.html = "<a href='http://test.com/#/param/val'>stuff</a>"

            c = subject.dup
            c.html = "<a href='http://test.com/#/param2/val'>stuff</a>"

            c.id.should_not == e.id
        end
    end

    describe '#to_rpc_data' do
        it "does not include 'dom_data'" do
            subject.html = html
            subject.dom.should be_true

            subject.to_rpc_data.should_not include 'dom_data'
        end
    end

    describe '.encode' do
        it "double encodes ';'" do
            described_class.encode( 'test;' ).should == 'test%253B'
        end

        it "double encodes '/'" do
            described_class.encode( 'test/' ).should == 'test%2F'
        end
    end

    describe '.decode' do
        it 'URL-decodes the passed string' do
            v = '%25+value%5C+%2B%3D%26%3B'
            described_class.decode( v ).should == URI.decode( v )
        end
    end
    describe '#decode' do
        it 'URL-decodes the passed string' do
            v = '%25+value%5C+%2B%3D%26%3B'
            subject.decode( v ).should == described_class.decode( v )
        end
    end

    describe '.extract_inputs' do
        it 'returns a hash of inputs and the matching template' do
            url       = "#{url}input1/value1/input2/value2"
            templates = [/input1\/(?<input1>\w+)\/input2\/(?<input2>\w+)/]

            template, inputs = described_class.extract_inputs( url, templates )
            templates.should == [template]
            inputs.should == {
                'input1' => 'value1',
                'input2' => 'value2'
            }
        end

        it 'decodes the input values' do
            url       = "#{url}input1/val%20ue1/input2/val%20ue2"
            templates = [/input1\/(?<input1>.+)\/input2\/(?<input2>.+)/]

            _, inputs = described_class.extract_inputs( url, templates )
            inputs.should == {
                'input1' => 'val ue1',
                'input2' => 'val ue2'
            }
        end

        context 'when no URL is given' do
            it 'returns an empty array' do
                described_class.extract_inputs( nil ).should == []
            end
        end

        context 'when no templates are given' do
            it "defaults to #{Arachni::OptionGroups::Audit}#link_templates" do
                url       = "#{url}input1/value1/input2/value2"
                templates = [/input1\/(?<input1>\w+)\/input2\/(?<input2>\w+)/]

                Arachni::Options.audit.link_templates = templates

                template, inputs = described_class.extract_inputs( url )
                inputs.should == {
                    'input1' => 'value1',
                    'input2' => 'value2'
                }

                [templates].should == [Arachni::Options.audit.link_templates]
            end
        end

        context 'when no matches are found' do
            it 'returns an empty array' do
                url       = "#{url}input3/value1/input4/value2"
                templates = [/input1\/(?<input1>\w+)\/input2\/(?<input2>\w+)/]

                described_class.extract_inputs( url, templates ).should == []
            end
        end
    end

    describe '.type' do
        it 'returns :link_template' do
            described_class.type.should == :link_template
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
            link.action.should == url + 'test2/param/myvalue'
            link.url.should == url
            link.inputs.should == {
                'param'  => 'myvalue'
            }
        end

        context 'when the URL matches a link template' do
            it 'includes it' do
                response = Arachni::HTTP::Response.new(
                    url: url + '/test2/param/myvalue'
                )

                link = described_class.from_response( response ).first
                link.action.should == url + 'test2/param/myvalue'
                link.url.should == link.action
                link.inputs.should == {
                    'param'  => 'myvalue'
                }
            end
        end
    end

    describe '.from_document' do
        context 'when the response does not contain any link templates' do
            it 'returns an empty array' do
                described_class.from_document( '', '' ).should be_empty
            end
        end
        context 'when the response contains link templates' do
            it 'returns an array of link templates' do
                html = '
                <html>
                    <body>
                        <a href="' + url + '/test2/param/myvalue"></a>
                    </body>
                </html>'

                link = described_class.from_document( url, html ).first
                link.action.should == url + 'test2/param/myvalue'
                link.url.should == url
                link.inputs.should == {
                    'param'  => 'myvalue'
                }
            end

            context 'and includes a base attribute' do
                it 'should return an array of link templates with adjusted URIs' do
                    base_url = "#{url}this_is_the_base/"
                    html = '
                    <html>
                        <head>
                            <base href="' + base_url + '" />
                        </head>
                        <body>
                            <a href="test/param/myvalue"></a>
                        </body>
                    </html>'

                    link = described_class.from_document( url, html ).first
                    link.action.should == base_url + 'test/param/myvalue'
                    link.url.should == url
                    link.inputs.should == {
                        'param'  => 'myvalue'
                    }
                end
            end
        end
    end
end
