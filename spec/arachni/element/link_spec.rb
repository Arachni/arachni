require 'spec_helper'

describe Arachni::Element::Link do
    it_should_behave_like 'element'
    it_should_behave_like 'with_node'
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

    subject { described_class.new( url: "#{url}submit", inputs: inputs ) }
    let(:inputs) { { 'name1' => 'value1', 'name2' => 'value2' } }
    let(:url) { utilities.normalize_url( web_server_url_for( :link ) ) }
    let(:http) { Arachni::HTTP::Client }
    let(:utilities) { Arachni::Utilities }
    let(:rewrite_rules) do
        {
            /articles\/[\w-]+\/(\d+)/ => 'articles.php?id=\1'
        }
    end

    let(:html) do
        '<html>
            <body>
                <a href="/stuff#?stuff=blah">Bla</a>
            </body>
        </html>'
    end
    let(:with_node) do
        described_class.from_document( url, html ).first
    end

    it 'is assigned to Arachni::Link for easy access' do
        Arachni::Link.should == described_class
    end

    describe '#initialize' do
        context 'when only a url is provided' do
            let(:url) { 'http://test.com/?one=2&three=4' }
            let(:link) { described_class.new( url: url ) }

            it 'is used for owner #url' do
                link.url.should == url
            end

            it 'is used for the #action' do
                link.action.should == url
            end

            it 'is parsed in order to extract #inputs' do
                link.inputs.should == { 'one' => '2', 'three' => '4' }
            end
        end

        context "when there are #{Arachni::OptionGroups::Scope}#link_rewrites" do
            it 'rewrites the #action' do
                Arachni::Options.scope.link_rewrites = rewrite_rules

                link = described_class.new(
                    url:    url,
                    action: "#{url}/articles/some-stuff/23"
                )
                link.action.should == url + 'articles.php?id=23'
                link.url.should == url
                link.inputs.should == { 'id'  => '23' }
            end
        end
    end

    describe '#dom' do
        context 'when #html has been assigned' do
            it "returns #{described_class::DOM}" do
                with_node.dom.should be_kind_of described_class::DOM
            end
        end

        context 'when a #node has not been assigned' do
            it 'returns nil' do
                subject.dom.should be_nil
            end
        end
    end

    describe '#id' do
        context 'when the action it contains path parameters' do
            it 'ignores them' do
                e = described_class.new( url: 'http://test.com/path;p=v?p1=v1&p2=v2', inputs: inputs )
                c = described_class.new( url: 'http://test.com/path?p1=v1&p2=v2', inputs: inputs )
                e.id.should == c.id
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

    describe '.rewrite' do
        let(:url) { 'http://test.com/articles/some-stuff/23' }

        it 'rewrites a URL based on the given rules' do
            described_class.rewrite( url, rewrite_rules ).should ==
                'http://test.com/articles.php?id=23'
        end

        context 'when no rules are provided' do
            it "uses the ones in #{Arachni::OptionGroups::Scope}#link_rewrites" do
                Arachni::Options.scope.link_rewrites = rewrite_rules

                described_class.rewrite( url ).should ==
                    'http://test.com/articles.php?id=23'
            end
        end
    end

    describe '.from_document' do
        context 'when the response does not contain any links' do
            it 'should return an empty array' do
                described_class.from_document( '', '' ).should be_empty
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
                link.action.should == url + 'test2?param_one=value_one&param_two=value_two'
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
                    link.action.should == base_url + 'test?param_one=value_one&param_two=value_two'
                    link.url.should == url
                    link.inputs.should == {
                        'param_one'  => 'value_one',
                        'param_two'  => 'value_two'
                    }
                end
            end
        end
    end

    describe '.from_response' do
        it 'returns all available links from an HTTP response' do
            res = Arachni::HTTP::Response.new(
                url: url + '/?param=val',
                body: '<a href="test?param_one=value_one&param_two=value_two"></a>'
            )
            described_class.from_response( res ).size.should == 2
        end
    end

    describe '.parse_query_vars' do
        it 'returns the query parameters as a Hash' do
            url = 'http://test/?param_one=value_one&param_two=value_two'
            described_class.parse_query_vars( url ).should == {
                'param_one' => 'value_one',
                'param_two' => 'value_two'
            }
        end
        context 'when passed' do
            describe 'nil' do
                it 'returns an empty Hash' do
                    described_class.parse_query_vars( nil ).should == {}
                end
            end
            describe 'an unparsable URL' do
                it 'returns an empty Hash' do
                    url = '$#%^$6#5436#$%^'
                    described_class.parse_query_vars( url ).should == {}
                end
            end
        end
    end

end
