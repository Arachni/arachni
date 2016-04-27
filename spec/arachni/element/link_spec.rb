require 'spec_helper'

describe Arachni::Element::Link do
    html = '<a href="/stuff#?stuff=blah">Bla</a>'

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
        expect(Arachni::Link).to eq(described_class)
    end

    describe '#initialize' do
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

        context "when there are #{Arachni::OptionGroups::Scope}#url_rewrites" do
            it 'rewrites the #action' do
                Arachni::Options.scope.url_rewrites = rewrite_rules

                link = described_class.new(
                    url:    url,
                    action: "#{url}/articles/some-stuff/23"
                )
                expect(link.action).to eq(url + 'articles.php')
                expect(link.url).to eq(url)
                expect(link.inputs).to eq({ 'id'  => '23' })
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

    describe '#simple' do
        it 'should return a simplified version as a hash' do
            expect(subject.simple).to eq({ subject.action => subject.inputs })
        end
    end

    describe '#to_s' do
        it 'returns a URL' do
            expect(subject.to_s).to eq("#{subject.action}?name1=value1&name2=value2")
        end
    end

    describe '#type' do
        it 'should be "link"' do
            expect(subject.type).to eq(:link)
        end
    end

    describe '#coverage_id' do
        it "takes into account #{described_class::DOM}#inputs.keys" do
            e = subject.dup
            e.source = '<a href="/stuff#?stuff=blah">Bla</a>'

            c = subject.dup
            c.source = '<a href="/stuff#?stuff=blooh">Bla</a>'

            expect(c.coverage_id).to eq(e.coverage_id)

            e = subject.dup
            e.source = '<a href="/stuff#?stuff=blah">Bla</a>'

            c = subject.dup
            c.source = '<a href="/stuff#?stuff2=blooh">Bla</a>'

            expect(c.coverage_id).not_to eq(e.coverage_id)
        end
    end

    describe '#id' do
        it "takes into account #{described_class::DOM}#inputs" do
            e = subject.dup
            e.source = '<a href="/stuff#?stuff=blah">Bla</a>'

            c = subject.dup
            c.source = '<a href="/stuff#?stuff=blah">Bla</a>'

            expect(c.id).to eq(e.id)

            e = subject.dup
            e.source = '<a href="/stuff#?stuff=blah">Bla</a>'

            c = subject.dup
            c.source = '<a href="/stuff#?stuff=blooh">Bla</a>'

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

        context 'when the response does not contain any links' do
            let(:link_html) do
                html = '
                    <html>
                        <body>
                        </body>
                    </html>'
            end

            it 'should return an empty array' do
                expect(described_class.from_parser( parser )).to be_empty
            end
        end

        context 'when links have actions that just fragments' do
            let(:link_html) do
                html = '
                    <html>
                        <body>
                            <a href="#stuff"></a>
                        </body>
                    </html>'
            end

            it 'ignores them' do
                expect(described_class.from_parser( parser )).to be_empty
            end
        end

        context 'when links have actions that are out of scope' do
            let(:link_html) do
                '
                    <html>
                        <body>
                            <a href="' + url + '/exclude?param_one=value_one&param_two=value_two"></a>

                            <a href="' + url + '/stuff?param_one=value_one&param_two=value_two"></a>
                        </body>
                    </html>'
            end

            it 'ignores them' do
                Arachni::Options.scope.exclude_path_patterns = [/exclude/]

                links = described_class.from_parser( parser )
                expect(links.size).to eq(1)
                expect(links.first.action).to eq(url + 'stuff')
            end
        end

        context 'when the response contains links' do
            let(:link_html) do
                '
                <html>
                    <body>
                        <a href="' + url + '/test2?param_one=value_one&param_two=value_two"></a>
                    </body>
                </html>'
            end

            it 'should return an array of links' do
                link = described_class.from_parser( parser ).first
                expect(link.action).to eq(url + 'test2')
                expect(link.url).to eq(url)
                expect(link.inputs).to eq({
                    'param_one'  => 'value_one',
                    'param_two'  => 'value_two'
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
                            <a href="test?param_one=value_one&param_two=value_two"></a>
                        </body>
                    </html>'
                end
                let(:base_url) { "#{url}this_is_the_base/" }

                it 'should return an array of links with adjusted URIs' do
                    ap parser.base

                    link = described_class.from_parser( parser ).first
                    expect(link.action).to eq(base_url + 'test')
                    expect(link.url).to eq(url)
                    expect(link.inputs).to eq({
                        'param_one'  => 'value_one',
                        'param_two'  => 'value_two'
                    })
                end
            end
        end

        context 'when its value is' do
            let(:link) { described_class.from_parser( parser ).first }
            let(:value) { 'a' * size }
            let(:href) { "test?param=#{value}" }
            let(:link_html) do
                tpl = '<html>
                           <body>
                               <a href="%s"></a>
                           </body>
                      </html>'

                tpl % href[0...size]
            end

            context "equal to #{described_class::MAX_SIZE}" do
                let(:size) { described_class::MAX_SIZE }

                it 'returns empty array' do
                    expect(link).to be_nil
                end
            end

            context "larger than #{described_class::MAX_SIZE}" do
                let(:size) { described_class::MAX_SIZE + 1 }

                it 'sets empty value' do
                    expect(link).to be_nil
                end
            end

            context "smaller than #{described_class::MAX_SIZE}" do
                let(:size) { described_class::MAX_SIZE - 1 }

                it 'leaves the values alone' do
                    expect(link.inputs['param']).not_to be_empty
                end
            end
        end
    end

    describe '.encode' do
        it 'URL-encodes the passed string' do
            v = '% value\ +=&;'
            expect(described_class.encode( v )).to eq('%25%20value%5C%20%2B%3D%26%3B')
        end
    end
    describe '#encode' do
        it 'URL-encodes the passed string' do
            v = '% value\ +=&;'
            expect(subject.encode( v )).to eq(described_class.encode( v ))
        end
    end

    describe '.decode' do
        it 'URL-decodes the passed string' do
            v = '%25%20value%5C%20%2B%3D%26%3B'
            expect(described_class.decode( v )).to eq(URI.decode( v ))
        end
    end
    describe '#decode' do
        it 'URL-decodes the passed string' do
            v = '%25%20value%5C%20%2B%3D%26%3B'
            expect(subject.decode( v )).to eq(described_class.decode( v ))
        end
    end

    describe '.from_response' do
        it 'returns all available links from an HTTP response' do
            res = Arachni::HTTP::Response.new(
                url:  url + '/?param=val',
                body: '<a href="test?param_one=value_one&param_two=value_two"></a>'
            )
            expect(described_class.from_response( res ).size).to eq(2)
        end
    end
end
