require 'spec_helper'

describe Arachni::Element::LinkTemplate do
    html = "<a href='http://test.com/param/val'>stuff</a>"

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

    describe '.encode' do
        it "double encodes ';'" do
            described_class.encode( 'test;' ).should == 'test%253B'
        end

        it "double encodes '/'" do
            described_class.encode( 'test/' ).should == 'test%2F'
        end
    end

    describe '.type' do
        it 'returns :link_template' do
            described_class.type.should == :link_template
        end
    end
end
