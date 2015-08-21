require 'spec_helper'

describe Arachni::Element::Input do
    html = '<input type=password name="my_first_input" value="my_first_value"" />'

    subject do
        described_class.new(
            action: url,
            source: html,
            method: 'onmouseover'
        )
    end
    let(:url) { 'http://test.com/' }

    it_should_behave_like 'dom_only', html
end
