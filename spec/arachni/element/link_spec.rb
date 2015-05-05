require 'spec_helper'

describe Arachni::Element::Link do
    html = '<a href="/stuff#?stuff=blah">Bla</a>'

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

    before :each do
        reset_options
    end

    subject { described_class.new( url: "#{url}submit", inputs: inputs, source: html ) }
    let(:inputs) { { 'name1' => 'value1', 'name2' => 'value2' } }
    let(:url) { utilities.normalize_url( web_server_url_for( :link ) ) }
    let(:http) { Arachni::HTTP::Client }
    let(:utilities) { Arachni::Utilities }
    let(:rewrite_rules) do
        { /articles\/[\w-]+\/(\d+)/ => 'articles.php?id=\1' }
    end

    it 'is assigned to Arachni::Link for easy access' do
        Arachni::Link.should == described_class
    end

    describe '#initialize' do
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
                inputs: option_inputs
            )
        end

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

        context "when there are #{Arachni::OptionGroups::Scope}#url_rewrites" do
            it 'rewrites the #action' do
                Arachni::Options.scope.url_rewrites = rewrite_rules

                link = described_class.new(
                    url:    url,
                    action: "#{url}/articles/some-stuff/23"
                )
                link.action.should == url + 'articles.php'
                link.url.should == url
                link.inputs.should == { 'id'  => '23' }
            end
        end
    end

    describe '#dom' do
        context 'when there are no DOM#inputs' do
            it 'returns nil' do
                subject.source = '<a href="/stuff">Bla</a>'
                subject.dom.should be_nil
            end
        end

        context 'when there is no #node' do
            it 'returns nil' do
                subject.source = nil
                subject.dom.should be_nil
            end
        end
    end

    describe '#simple' do
        it 'should return a simplified version as a hash' do
            subject.simple.should == { subject.action => subject.inputs }
        end
    end

    describe '#to_s' do
        it 'returns a URL' do
            subject.to_s.should == "#{subject.action}?name1=value1&name2=value2"
        end
    end

    describe '#type' do
        it 'should be "link"' do
            subject.type.should == :link
        end
    end

    describe '#coverage_id' do
        it "takes into account #{described_class::DOM}#inputs.keys" do
            e = subject.dup
            e.source = '<a href="/stuff#?stuff=blah">Bla</a>'

            c = subject.dup
            c.source = '<a href="/stuff#?stuff=blooh">Bla</a>'

            c.coverage_id.should == e.coverage_id

            e = subject.dup
            e.source = '<a href="/stuff#?stuff=blah">Bla</a>'

            c = subject.dup
            c.source = '<a href="/stuff#?stuff2=blooh">Bla</a>'

            c.coverage_id.should_not == e.coverage_id
        end
    end

    describe '#id' do
        it "takes into account #{described_class::DOM}#inputs" do
            e = subject.dup
            e.source = '<a href="/stuff#?stuff=blah">Bla</a>'

            c = subject.dup
            c.source = '<a href="/stuff#?stuff=blah">Bla</a>'

            c.id.should == e.id

            e = subject.dup
            e.source = '<a href="/stuff#?stuff=blah">Bla</a>'

            c = subject.dup
            c.source = '<a href="/stuff#?stuff=blooh">Bla</a>'

            c.id.should_not == e.id
        end
    end

    describe '#to_rpc_data' do
        it "does not include 'dom_data'" do
            subject.source = html
            subject.dom.should be_true

            subject.to_rpc_data.should_not include 'dom_data'
        end
    end

    describe '.from_document' do
        context 'when the response does not contain any links' do
            it 'should return an empty array' do
                described_class.from_document( '', '' ).should be_empty
            end
        end
        context 'when links have actions that are out of scope' do
            it 'ignores them' do
                html = '
                    <html>
                        <body>
                            <a href="' + url + '/exclude?param_one=value_one&param_two=value_two"></a>

                            <a href="' + url + '/stuff?param_one=value_one&param_two=value_two"></a>
                        </body>
                    </html>'

                Arachni::Options.scope.exclude_path_patterns = [/exclude/]

                links = described_class.from_document( url, html )
                links.size.should == 1
                links.first.action.should == url + 'stuff'
            end
        end
        context 'when the response contains links' do
            it 'should return an array of links' do
                html = '
                <html>
                    <body>
                        <a href="' + url + '/test2?param_one=value_one&param_two=value_two"></a>
                    </body>
                </html>'

                link = described_class.from_document( url, html ).first
                link.action.should == url + 'test2'
                link.url.should == url
                link.inputs.should == {
                    'param_one'  => 'value_one',
                    'param_two'  => 'value_two'
                }
            end
            context 'and includes a base attribute' do
                it 'should return an array of links with adjusted URIs' do
                    base_url = "#{url}this_is_the_base/"
                    html = '
                    <html>
                        <head>
                            <base href="' + base_url + '" />
                        </head>
                        <body>
                            <a href="test?param_one=value_one&param_two=value_two"></a>
                        </body>
                    </html>'

                    link = described_class.from_document( url, html ).first
                    link.action.should == base_url + 'test'
                    link.url.should == url
                    link.inputs.should == {
                        'param_one'  => 'value_one',
                        'param_two'  => 'value_two'
                    }
                end
            end
        end
    end

    describe '.encode_query_params' do
        it "encodes '='" do
            v = 'stuff='
            described_class.encode_query_params( v ).should == 'stuff%3D'
        end
    end
    describe '#encode_query_params' do
        it "encodes '='" do
            v = 'stuff='
            subject.encode_query_params( v ).should ==
                described_class.encode_query_params( v )
        end
    end

    describe '.encode' do
        it 'URL-encodes the passed string' do
            v = '% value\ +=&;'
            described_class.encode( v ).should == URI.encode( v )
        end
    end
    describe '#encode' do
        it 'URL-encodes the passed string' do
            v = '% value\ +=&;'
            subject.encode( v ).should == described_class.encode( v )
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

    describe '.from_response' do
        it 'returns all available links from an HTTP response' do
            res = Arachni::HTTP::Response.new(
                url:  url + '/?param=val',
                body: '<a href="test?param_one=value_one&param_two=value_two"></a>'
            )
            described_class.from_response( res ).size.should == 2
        end
    end
end
