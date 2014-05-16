require 'spec_helper'

describe Arachni::Element::LinkTemplate do
    it_should_behave_like 'element'
    it_should_behave_like 'auditable'

    def auditable_extract_parameters( resource )
        YAML.load( resource.body )
    end

    def run
        http.run
    end

    subject do
        described_class.new(
            url:      "#{url}param/val",
            template: /param\/(?<param>\w+)/
        )
    end
    let(:inputable) do
        described_class.new(
            url:      "#{url}input1/value1/input2/value2",
            template: /input1\/(?<input1>\w+)\/input2\/(?<input1>\w+)/
        )
    end
    let(:url) { utilities.normalize_url( web_server_url_for( :link_template ) ) }
    let(:http) { Arachni::HTTP::Client }
    let(:utilities) { Arachni::Utilities }

    describe '.encode' do
        it "double encodes ';'" do
            described_class.encode( 'test;' ).should == 'test%253B'
        end

        it "double encodes '/'" do
            described_class.encode( 'test/' ).should == 'test%252F'
        end
    end
end
